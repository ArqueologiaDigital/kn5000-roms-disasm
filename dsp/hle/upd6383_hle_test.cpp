// license:BSD-3-Clause
// copyright-holders:Felipe Sanches
//
// upd6383_hle_test.cpp -- offline golden A/B for the C++ HLE reference kernels.
//
// Anchors the C++ port (upd6383_hle.h) to the validated Python reference WITHOUT a MAME build:
//   * SEC = the six REAL captured biquad sections (from the running effects DSP), in the decoded
//     (b0,b1,b2,a1,a2,makeup) order -- the same coefficients render_eq_from_capture.py uses.
//   * GOLD = each section's magnitude response (dB) at 100/440/1000/4000/8000 Hz, computed by the
//     Python BiquadDF1 (dsp/hle/kernels.py) on those exact coefficients.
// The C++ BiquadDF1 must reproduce GOLD to < 0.001 dB, and the C++ process_one must match its own
// analytic response (impulse-FFT sanity) -- proving the port is faithful.  Also checks OnePole and
// DelayLine defining properties.
//
//   c++ -std=c++17 -O2 dsp/hle/upd6383_hle_test.cpp -o /tmp/hle_test && /tmp/hle_test

#include "upd6383_hle.h"
#include <cmath>
#include <cstdio>
#include <complex>
#include <vector>

using namespace upd6383_hle;

static const double FS = 44100.0;
static const double FREQ[5] = { 100.0, 440.0, 1000.0, 4000.0, 8000.0 };

// exact captured sections (b0,b1,b2,a1,a2,mk) and golden magnitude dB (Python BiquadDF1)
static const double SEC[6][6] = {
	{0.495000000, -0.972000000, 0.478000000, -0.972000000, 0.945000000, 0.500000000},
	{0.490000000, -0.946000000, 0.456000000, -0.946000000, 0.893000000, 0.500000000},
	{0.417000000, -0.777000000, 0.362000000, -0.777000000, 0.558000000, 0.500000000},
	{0.431000000, -0.814000000, 0.384000000, -0.814000000, 0.630000000, 0.500000000},
	{0.576000000, -0.695000000, 0.166000000, -0.695000000, 0.483000000, 0.500000000},
	{0.799000000, -0.458000000, -0.194000000, -0.458000000, 0.209000000, 0.500000000},
};
static const double GOLD[6][5] = {
	{-66.381393, -62.815696, -46.346729, -18.796538, 4.572705},
	{-71.674378, -56.488059, -44.756994, -18.725567, 3.558956},
	{-57.533415, -53.019584, -43.915276, -19.454180, -5.357425},
	{-63.147640, -54.666411, -44.218069, -19.182784, -3.641622},
	{-30.455034, -29.558550, -26.878504, -14.553511, -4.989256},
	{-20.150166, -19.522765, -17.499109, -8.353021, -3.844594},
};

static int g_fail = 0;
static void check(const char *name, bool ok, const char *detail = "")
{
	std::printf("  [%s] %-46s %s\n", ok ? "PASS" : "FAIL", name, detail);
	if (!ok) g_fail++;
}

// DFT magnitude of the impulse response at f, to cross-check process_one vs. the analytic form.
static double impulse_mag(BiquadDF1 bq, double f)
{
	const int N = 8192;
	std::complex<double> acc(0.0, 0.0);
	for (int n = 0; n < N; n++)
	{
		double x = (n == 0) ? 1.0 : 0.0;
		double y = bq.process_one(x);
		acc += y * std::exp(std::complex<double>(0.0, -2.0 * M_PI * f * n / FS));
	}
	return std::abs(acc);
}

int main()
{
	std::printf("upd6383_hle C++ reference -- offline golden A/B vs the Python reference:\n");

	double worst = 0.0;
	for (int s = 0; s < 6; s++)
	{
		BiquadDF1 bq(SEC[s][0], SEC[s][1], SEC[s][2], SEC[s][3], SEC[s][4], SEC[s][5]);
		for (int k = 0; k < 5; k++)
		{
			double dB = 20.0 * std::log10(bq.response(FREQ[k], FS) + 1e-12);
			worst = std::max(worst, std::fabs(dB - GOLD[s][k]));
		}
	}
	char buf[64];
	std::snprintf(buf, sizeof buf, "max |Δ| = %.6f dB", worst);
	check("C++ biquad response == Python golden (all 6 secs)", worst < 1e-3, buf);

	// process_one impulse-FFT must equal the analytic response (a mid section, avoid DC-notch sec 0)
	{
		BiquadDF1 a(SEC[4][0], SEC[4][1], SEC[4][2], SEC[4][3], SEC[4][4], 1.0);
		BiquadDF1 b(SEC[4][0], SEC[4][1], SEC[4][2], SEC[4][3], SEC[4][4], 1.0);
		double imp = 20.0 * std::log10(impulse_mag(a, 1000.0) + 1e-12);
		double ana = 20.0 * std::log10(b.response(1000.0, FS) + 1e-12);
		std::snprintf(buf, sizeof buf, "impulse %.3f vs analytic %.3f dB", imp, ana);
		check("process_one impulse-FFT == analytic response", std::fabs(imp - ana) < 0.05, buf);
	}

	// OnePole: y = (1-d)x + d*y1 -- step response approaches x with time constant d.
	{
		OnePole op(0.6);
		double y = 0.0;
		for (int i = 0; i < 200; i++) y = op.process_one(1.0);
		check("one-pole step response converges to input", std::fabs(y - 1.0) < 1e-3);
	}

	// DelayLine: read(d) returns the sample written d steps ago.
	{
		DelayLine dl(64);
		for (int i = 1; i <= 10; i++) dl.write(double(i));
		double r = dl.read(3.0);   // 3 samples back from the last write (10) -> 7
		check("delay read(3) returns sample 3 back", std::fabs(r - 7.0) < 1e-9,
		      (std::snprintf(buf, sizeof buf, "got %.1f want 7.0", r), buf));
	}

	std::printf("\n%s\n", g_fail == 0 ? "ALL C++ HLE GOLDEN CHECKS PASSED" : "SOME CHECKS FAILED");
	return g_fail == 0 ? 0 : 1;
}
