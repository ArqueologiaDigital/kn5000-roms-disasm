# v7: the `ret` at 0xFB5B02 and the routine at 0xFB5B03 are v10/v9's LoadRegion1_OpenSuccess_Helper /
# _Helper2 (0xFB62C3 / 0xFB62C4).  v7 called them LoadRegion1_OpenSuccess_Data and
# FileIO_ByteBlock_DemoProc1_Helper4, a name v10/v9 give to the `ret` at v7 0xFB5AF4.
s/\bFileIO_ByteBlock_DemoProc1_Helper4\b/LoadRegion1_OpenSuccess_Helper2/g
s/\bLoadRegion1_OpenSuccess_Data\b/LoadRegion1_OpenSuccess_Helper/g
