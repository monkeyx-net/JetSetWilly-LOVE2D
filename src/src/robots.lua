-- robots.lua  -- All 45 robot sprite types, 60-level start tables, AI movement

local band, bor = bit.band, bit.bor

-- ── Sprite data ─────────────────────────────────────────────────────────────
-- robotGfx[i] is an array of frames (each frame = 16 u16 values)
-- Indices are 0-based to match C source

local robotGfx = {
    [0]  = {{15,63,15,12303,3087,783,207,47,8,16376,16368,16366,8159,8155,4091,4091},{15,63,15,15,15,15,15,16367,8,16376,16368,16366,8159,8155,4091,4091},{943,447,399,399,32655,32655,18383,4047,8,16376,16368,16366,8159,8155,4091,4091},{15,1087,7727,15151,23951,3727,1999,4047,8,16376,16368,16366,8159,8155,4091,4091}},
    [1]  = {{0,0,10922,32767,32767,31807,31807,32767,32767,32767,0,10922,0,10922,0,0},{72,300,1212,4862,19454,11903,48191,65148,65522,32713,32549,15508,12880,2368,1280,1024},{0,2016,4080,6120,4080,5736,3696,5736,4080,6120,4080,6120,2064,6120,4104,0},{4608,13440,15648,32584,32722,65140,64573,15999,20479,37886,42238,10556,2636,656,160,32}},
    [2]  = {{0,0,0,514,8706,43348,43224,29044,8922,15278,11947,9465,8411,8408,340,650},{0,514,514,372,216,20820,21242,9182,59307,7929,6361,2265,2388,1674,1024,0},{514,910,248,340,730,1022,4491,19369,11259,38648,27864,1364,650,256,128,64},{0,514,514,372,216,20820,21242,9182,59307,7929,6361,2265,2388,1674,1024,0}},
    [3]  = {{8196,44780,47997,57351,48565,40964,15228,0,7600,8196,15228,41540,64951,40964,15324,8196},{8196,14260,40964,64383,40964,15796,8196,7032,0,15796,41540,47997,57351,48565,47084,8196},{8196,15068,15805,57351,15221,8196,15804,0,7024,8196,15805,41541,64375,40965,15853,8196},{8196,15221,40965,64959,40965,15221,8196,7608,0,15220,9348,15805,57351,15221,12012,8196}},
    [4]  = {{4080,6120,6168,14284,10276,21394,25674,43307,43563,27210,27026,9252,13260,6168,6120,4080},{224,2032,14360,29644,25638,18835,21067,54315,54570,54474,53778,18916,9228,5108,2168,1920},{384,2016,6168,29646,42021,51605,53845,54357,54421,53797,51657,58387,29670,6168,2016,384},{1792,2272,8156,12326,26514,51274,54058,54443,21547,21067,18835,9254,13260,10264,8176,480}},
    [5]  = {{3072,3072,3072,3072,3072,7680,4608,13056,16128,29568,24960,24960,49344,49344,32832,32832},{2112,2112,3264,1152,1920,1920,3264,7392,15216,12336,24600,24600,16392,49164,32772,32772},{528,528,816,288,480,480,816,1848,3804,3084,6150,6150,4098,12291,8193,8193},{48,48,48,48,48,120,72,204,252,462,390,390,771,771,513,513}},
    [6]  = {{0,0,0,32766,16386,65535,56955,49155,49155,56955,65535,16386,32766,0,0,0},{2560,7424,13952,26432,50080,29136,47208,23604,11322,5661,2958,1475,742,364,184,80},{2016,8184,5160,5736,5736,5736,5736,5160,5160,5736,5736,5736,5736,5160,8184,2016},{80,184,364,742,1475,2958,5661,11322,23604,47208,29136,50080,26432,13952,7424,2560}},
    [7]  = {{32256,39168,65280,33024,32256,6144,9216,9216,16896,16896,33024,59136,42240,49920,42240,59136},{0,8064,9792,14784,12480,8064,2304,4224,8256,16416,32784,57456,41040,49200,41040,57456},{0,0,0,2016,2448,3696,3696,1632,7128,24582,32769,57351,40965,49155,40965,57351},{0,504,612,924,780,504,144,264,516,1026,2049,3591,2565,3075,2565,3591}},
    [8]  = {{3072,4608,8464,4640,35904,21120,12032,12032,24448,24448,24448,0,65472,23936,23936,65472},{1,2,33540,19656,8976,5280,3008,3008,6112,6112,6112,0,16368,7088,7088,16368},{32768,16384,8193,4578,2244,1320,752,752,1528,1528,1528,0,4092,2932,2932,4092},{0,0,2096,1228,561,330,188,188,382,382,382,0,1023,749,749,1023}},
    [9]  = {{14336,31744,32256,28032,17472,27712,31776,31744,31756,31794,64716,65328,64704,32512,27648,14336},{3680,8084,7944,6944,4432,6992,8096,8096,32576,57152,57216,40832,32512,7936,6912,3584},{896,1984,2016,1752,1092,3780,32706,61376,61376,36800,30656,1984,1984,1984,1728,896},{224,496,496,434,277,437,506,506,2036,3572,3576,2552,2032,496,432,224}},
    [10] = {{3072,5632,12032,12032,20352,24448,24448,40896,49088,48576,47808,48448,23168,23936,16128,3072},{0,0,0,112,920,3192,13304,18416,24560,49136,48800,48480,23232,23872,16256,3584},{0,0,0,0,960,7288,8700,20478,24574,40959,49135,24406,24494,9044,8184,960},{0,0,0,3584,6080,6128,5116,3070,3070,3031,1515,1495,746,638,396,112}},
    [11] = {{1984,6192,9096,17476,34850,36883,36883,34850,17476,9096,6192,1984,768,768,768,896},{1984,6192,8200,17284,33858,34851,34851,33858,17284,8200,6192,1984,3968,7632,2272,1088}},
    [12] = {{1984,8176,15992,31804,32380,65534,65534,61440,65408,32752,32764,16376,8176,1984,0,0},{1984,8176,15608,30844,31996,65408,64512,61440,63488,32256,32640,16352,8176,1984,0,0}},
    [13] = {{1984,2080,2720,2080,2976,4112,9544,2720,15736,18116,1984,640,1344,4064,5248,2240},{1984,2080,2720,2080,14648,0,1344,2720,7536,5840,6096,2720,1344,4064,592,1568}},
    [14] = {{384,0,384,17809,384,35234,17809,384,52659,52659,52659,52659,9156,4680,3504,0},{384,0,384,35234,384,17809,35234,384,52659,52659,52659,52659,9156,4680,3504,0}},
    [15] = {{5632,5632,5632,5632,5632,5632,5632,5632,65472,0,21120,49344,13056,45888,2048,11520},{1408,1408,1408,1408,1408,1408,1408,1408,16368,0,3360,9216,3280,3312,10240,3360},{352,352,352,352,352,352,352,352,4092,0,720,64,2868,816,3084,1320},{88,88,88,88,88,88,88,88,1023,0,300,5,972,716,9,300},{64,384,576,1472,3008,3008,6080,6080,5696,5632,5632,5632,5632,5632,5632,5632},{768,4032,2112,4896,4896,2112,4032,1920,1408,1408,1408,1408,1408,1408,1408,1408},{2048,3584,2816,2944,3008,3008,3040,4064,2400,352,352,352,352,352,352,352},{48,220,188,382,382,188,188,88,88,88,88,88,88,88,88,88}},
    [16] = {{3,15,31,32831,49279,53759,24575,40959,53247,54271,57340,65520,65504,32704,16256,3584},{0,0,20481,55299,39943,20255,55295,56319,65535,65535,65535,65535,36862,2044,1016,224},{0,896,1984,36800,57312,56305,22527,36863,57343,57343,65535,64639,63551,28735,31,14},{56,254,511,33791,51199,57343,24575,39935,51199,57343,57287,65281,65024,31744,14336,0}},
    [17] = {{960,3824,7672,16124,21454,26022,42023,29071,49143,21999,28278,21450,14364,5752,3056,704},{960,3568,6904,16380,20876,25638,50599,46031,23995,43639,24570,29262,14364,7224,3056,704},{960,3056,5496,16380,20492,26022,51175,61839,48767,56823,11322,23134,11324,5752,3056,960},{960,3568,6904,16380,20876,25638,50599,46031,23995,43639,24570,29262,14364,7224,3056,704}},
    [18] = {{3584,5376,10880,5888,65280,5632,3072,8064,16256,32512,10752,32512,28416,32512,6144,14336},{896,1344,2720,1472,32704,1408,768,2016,4064,8128,2688,8128,7104,8128,6272,14336},{224,336,680,368,4080,352,192,504,1016,2032,672,2032,1776,2032,1584,96},{56,84,170,92,508,88,48,126,254,508,168,508,444,508,280,56},{7168,10752,21760,14848,16256,6656,3072,32256,32512,16256,5376,16256,15744,16256,6272,7168},{1792,2688,5440,3712,4080,1664,768,8064,8128,4064,1344,4064,3936,4064,3168,1536},{448,672,1360,928,1022,416,192,2016,2032,1016,336,1016,984,1016,280,28},{112,168,340,232,255,104,48,504,508,254,84,254,246,254,24,28}},
    [19] = {{0,0,0,0,0,0,0,0,0,0,0,0,1536,16128,7936,3328},{0,0,0,0,0,0,0,384,4032,1856,832,20288,1856,800,3872,34592},{96,1008,464,208,976,464,200,968,456,200,3016,8648,200,3012,452,8388},{0,0,0,0,0,24,252,116,52,244,116,310,250,634,58,1274},{0,0,0,0,0,0,0,0,0,0,0,0,12288,32256,31744,22528},{0,0,0,0,0,0,0,3072,8064,5888,5632,6016,5888,9744,10112,9992},{768,2016,1472,1408,1504,1472,2432,2528,2512,2432,2536,2498,2432,4584,4544,4482},{0,0,0,0,0,192,504,368,352,376,368,608,632,624,609,632}},
    [20] = {{0,0,0,0,0,4928,6016,16320,21824,64160,64832,8096,2176,1280,0,0},{0,0,0,0,0,2256,1504,4080,5808,15696,16040,1872,680,596,40,20},{0,0,0,0,0,564,376,1020,1364,4010,4052,506,136,260,0,0},{3,10,21,10,21,171,86,235,341,1003,1023,126,34,34,0,0},{32768,20480,43008,20480,43008,54528,27136,55040,43648,55232,65472,32256,17408,17408,0,0},{0,0,0,0,0,11328,7808,16320,10912,22000,11248,24448,4352,8320,0,0},{0,0,0,0,0,2832,1952,4080,3432,2748,5500,2784,5440,10816,5120,10240},{0,0,0,0,0,712,488,1020,682,1375,703,1528,272,160,0,0}},
    [21] = {{2720,5456,2720,1346,1349,1349,1986,3426,4067,15487,31679,61411,44770,18370,52928,49376},{49152,51872,54608,51872,17728,17730,42949,52581,28642,31866,15039,4079,3811,1986,1762,3586}},
    [22] = {{768,1152,1472,2976,5440,5984,5984,8160,5008,11624,12152,12152,12152,12152,44921,32766},{192,288,368,744,1360,1496,1496,2040,2504,5812,6076,6076,6076,6076,38845,32766}},
    [23] = {{30208,0,28160,30208,28160,0,30208,28160,0,30208,0,0,28160,30208,0,28160},{7552,10752,10080,20912,19408,36992,43752,38072,37248,43736,37120,21760,19376,11104,9216,7552},{960,3120,4248,12820,26754,16426,46353,51269,42129,39429,18498,21770,10324,4744,3440,960},{440,84,1764,3466,3026,265,5973,7465,393,6997,137,170,3538,1748,36,440}},
    [24] = {{0,1536,2048,14336,20480,61440,63488,15360,15872,32256,40704,7936,8128,3776,6144,24576},{0,0,3840,5248,15360,3584,16128,3968,8064,12224,4032,2032,944,256,512,1024},{0,96,128,896,3328,1792,896,1984,3040,2016,2544,496,508,236,384,1536},{0,0,4,8,112,160,480,112,504,120,508,124,124,127,59,240},{1024,1024,3072,3072,5632,7680,15872,27648,40448,16128,16128,16128,32512,22016,7168,1536},{1152,2112,4896,4896,6048,4896,8160,7008,10128,4032,4032,4032,4032,7552,896,256},{128,128,192,192,416,480,496,216,484,1008,1008,1008,1016,424,224,384},{72,132,306,258,378,378,510,438,633,252,252,252,252,110,112,32}},
    [25] = {{15360,28160,42752,42240,30464,41728,25088,11264,13312,17920,50432,60928,42240,58624,30208,15360},{0,0,176,328,1020,68,524,636,13784,18160,50432,60928,42240,58624,30208,15360},{0,0,0,0,0,0,0,0,13364,17990,50629,61166,42405,58853,30326,15420},{0,0,3840,7040,15936,12352,8704,16320,4788,3398,197,238,165,229,118,60}},
    [26] = {{960,1632,3568,6872,13660,8196,32766,55157,45607,55157,32766,5496,9636,576,4488,0},{960,1632,3568,6840,13660,8196,32766,44779,58445,44779,32766,5496,2640,384,1056,256},{960,1632,3568,6872,13660,8196,32766,60891,43155,60891,32766,5496,9636,576,4488,1056},{960,1632,3568,6888,13660,8196,32766,56247,51477,56247,32766,5496,2626,16784,1024,4420}},
    [27] = {{2016,4080,57339,16380,8184,8184,12684,27222,45453,40697,3568,7608,13932,22938,35889,2016},{2016,4080,8184,65535,8184,8184,12684,10836,29070,40697,36337,7608,12876,22554,19506,2016},{2016,4080,8184,57339,16380,8184,12684,10836,12428,24058,36273,39513,4680,6168,11316,51171},{2016,36849,24570,16380,8184,4488,11892,10836,29070,24314,36337,7608,4680,30750,35889,2016}},
    [28] = {{5379,10942,5470,19112,13660,35502,27996,39417,28351,56675,11849,22913,1154,11206,4860,3325}},
    [29] = {{16552,64852,31400,5458,15020,30033,15030,40857,64886,50875,37492,33178,16672,25556,16200,48944}},
    [30] = {{64959,49135,60119,43589,26836,18564,16388,16385,20480,4618,16396,10786,5288,8324,5160,1312},{64959,65531,44247,43729,10836,33348,16897,2052,18960,8834,2216,5124,2704,320,0,0}},
    [31] = {{3072,13952,32576,32384,64768,65152,65408,65280,21760,10752,5120,10752,5120,2048,5120,2048},{768,3488,8144,8096,16192,16288,16352,16320,13632,10880,1280,2688,1280,512,1280,512},{192,872,2036,2024,4048,4072,4088,4080,1360,2720,320,672,2368,128,320,128},{48,218,509,506,1012,1018,1022,1020,852,680,80,168,80,32,80,32}},
    [32] = {{1024,10880,21824,11136,17472,44960,24384,8320,21824,10880,1024,1024,2048,15872,16640,33024},{512,5440,10912,5568,8736,24400,10912,4160,10912,5440,512,512,3584,4480,8256,0},{64,680,1364,936,1092,3050,1524,520,1364,680,64,64,112,392,516,0},{32,340,682,468,546,1405,762,340,682,340,32,32,16,124,130,129}},
    [33] = {{0,0,0,0,0,28480,48000,30016,6784,1280,128,0,0,0,0,0},{0,0,160,320,640,336,13984,23920,14304,960,0,0,0,0,0,0},{0,0,0,0,0,244,6584,12116,6568,80,8,0,0,0,0,0},{0,0,0,0,0,61,894,1495,874,20,40,20,10,0,0,0},{0,0,0,0,0,48128,32448,60320,22208,10240,5120,10240,20480,0,0,0},{0,0,0,0,0,12032,7576,10996,5528,2560,4096,0,0,0,0,0},{0,0,1280,640,320,2688,1388,3770,2028,960,0,0,0,0,0,0},{0,0,0,0,0,758,477,686,344,160,256,0,0,0,0,0}},
    [34] = {{6144,15360,54272,11776,14848,14848,23040,23808,20224,17152,8576,8704,7680,5120,4864,15360},{1536,3840,16128,2944,3712,3712,7936,6016,4544,4192,2112,2176,1920,512,512,1792},{384,3008,1344,2784,928,928,1440,1488,1264,1072,536,544,480,320,1584,320},{96,176,848,184,232,232,360,372,316,268,134,136,120,37,34,116},{1536,3328,2752,7424,5888,5888,5760,11904,15488,12416,24832,4352,7680,41984,17408,11776},{384,976,672,1872,1472,1472,1440,2976,3872,3104,6208,1088,1920,640,3168,640},{96,240,252,464,368,368,248,488,904,1544,528,272,480,64,64,224},{24,60,43,116,92,92,90,186,242,194,388,68,120,80,400,120}},
    [35] = {{3072,4608,8448,11520,8448,4608,3072,3072,7680,0,14080,16384,3392,44096,16512,11776},{3776,7584,7936,8160,7936,7584,3776,768,1920,0,3776,32,11008,9040,4192,1792},{1032,1560,1848,4092,1848,1752,1224,192,480,0,464,1032,2260,2752,8,944},{220,366,62,510,62,366,220,48,120,0,184,258,689,53,256,220}},
    [36] = {{0,0,2016,8120,15852,32766,32246,64503,64503,32750,32734,16380,8184,2016,0,0},{0,384,2016,3440,8184,16380,16372,32254,31734,15340,16348,7992,4080,2016,384,0},{384,2016,4080,7928,8056,16252,15356,14324,14332,16364,16364,8152,7992,4080,2016,384},{0,384,2016,4080,7864,16380,16372,31742,30710,14316,16348,7992,4080,2016,384,0}},
    [37] = {{32768,16384,41824,21344,10688,5792,3040,1904,680,1492,554,997,994,865,866,1904},{0,0,1584,22064,43456,22176,3040,1584,1000,1492,554,996,1002,5988,3680,1136},{0,0,864,864,448,7840,11232,22196,41834,17877,33314,993,994,864,864,1904},{0,0,1584,22064,43456,22176,3040,2036,554,1493,546,993,992,884,824,1808}},
    [38] = {{516,1294,2692,5572,5956,11236,12256,4676,2178,1836,5456,10916,21828,43652,17664,7616},{512,1280,2692,5582,5956,11236,12260,4676,2176,1796,5458,10924,21824,43652,17668,7620}},
    [39] = {{4,1798,12196,24532,12388,16916,12896,8132,2178,1836,5456,10916,21828,43652,17664,3264},{0,1792,12196,20566,8740,21076,16356,5956,2176,1796,5458,10924,21824,43652,17668,6532}},
    [40] = {{14316,30702,0,28662,61431,61431,54619,56251,54619,57339,60791,61175,28022,0,30702,14316}},
    [41] = {{768,960,480,320,480,1920,8184,16380,14188,5272,4080,4080,4080,576,576,1632},{768,960,480,320,480,1920,8184,16380,14188,5272,4080,4080,4080,576,1600,608},{768,960,480,320,480,1920,8188,16382,14182,5266,4080,4080,4080,576,576,1632},{768,960,480,320,480,1920,8191,16382,14176,5264,4080,4080,4080,576,576,1632}},
    [42] = {{4224,4224,4224,4224,4224,4224,4224,8320,8320,18498,34869,33801,32769,32770,17293,15478}},
    [43] = {{768,960,480,320,480,1920,8184,16380,0,0,0,0,0,0,0,0},{768,960,480,320,480,1920,8184,16380,0,0,0,0,0,0,0,0},{768,960,480,320,480,1920,8188,16382,0,0,0,0,0,0,0,0},{768,960,480,320,480,1920,8191,16382,0,0,0,0,0,0,0,0}},
    [44] = {{0,0,0,0,0,0,0,0,14188,5272,4080,4080,4080,576,576,1632},{0,0,0,0,0,0,0,0,14188,5272,4080,4080,4080,576,1600,608},{0,0,0,0,0,0,0,0,14182,5266,4080,4080,4080,576,576,1632},{0,0,0,0,0,0,0,0,14176,5264,4080,4080,4080,576,576,1632}},
}

-- Convert C-style POS(x,y) macro: pos = y*WIDTH + x*8
local function POS(x, y) return y * WIDTH + x * 8 end

-- Robot table constructor helpers
local function NOROBOT() return {pos=0, min=0, max=0, DoMove=DoNothing, DoDraw=DoNothing, speed=0, gfx=nil, ink=0, fUpdate=0, fIndex=0, fMask=0} end

-- Forward declarations for movement functions
local DoMoveLeft, DoMoveRight, DoMoveUp, DoMoveDown
local DoMoveStatic, DoMoveArrowLeft, DoMoveArrowRight, DoMoveMaria
local DoDrawRobot, DoDrawArrow, DoDrawToilet

-- ── Robot start state for all 60 levels (0-based level index) ─────────────
-- Each entry: {pos, min, max, DoMove, DoDraw, speed, gfx(0-based idx), ink, fUpdate, fIndex, fMask}
-- We use a lazy init via closures referencing movement functions defined later

local function mkRobot(pos, mn, mx, moveFn, drawFn, spd, gfxIdx, ink, fUpd, fIdx, fMask)
    return {pos=pos, min=mn, max=mx, DoMove=moveFn, DoDraw=drawFn, speed=spd,
            gfxIdx=gfxIdx, ink=ink, fUpdate=fUpd, fIndex=fIdx, fMask=fMask}
end

-- Robot start definitions per level (0-indexed)
-- Populated after movement functions are defined (see Robots_Init)
local robotStartDef  -- forward declare

-- ── Active robots ────────────────────────────────────────────────────────────
local robotThis = {}

local curRobot  -- pointer to current robot being processed

-- ── Movement functions ───────────────────────────────────────────────────────

DoMoveLeft = function()
    if curRobot.fIndex > 0 then
        curRobot.fIndex = curRobot.fIndex - 1
    else
        if curRobot.pos > curRobot.min then
            curRobot.pos    = curRobot.pos - 8
            curRobot.fIndex = 3
        else
            curRobot.DoMove = DoMoveRight
            curRobot.fIndex = curRobot.fIndex + 4
        end
    end
end

DoMoveRight = function()
    if curRobot.fIndex < 7 then
        curRobot.fIndex = curRobot.fIndex + 1
    else
        if curRobot.pos < curRobot.max then
            curRobot.pos    = curRobot.pos + 8
            curRobot.fIndex = 4
        else
            curRobot.DoMove = DoMoveLeft
            curRobot.fIndex = band(curRobot.fIndex, 3)
        end
    end
end

DoMoveUp = function()
    curRobot.fUpdate = bit.bxor(curRobot.fUpdate, 1)
    if curRobot.fUpdate ~= 0 then
        curRobot.fIndex = curRobot.fIndex + 1
    end
    curRobot.pos = curRobot.pos - curRobot.speed * WIDTH
    if curRobot.pos <= curRobot.min then
        curRobot.pos    = curRobot.min
        curRobot.DoMove = DoMoveDown
    end
end

DoMoveDown = function()
    curRobot.fUpdate = bit.bxor(curRobot.fUpdate, 1)
    if curRobot.fUpdate ~= 0 then
        curRobot.fIndex = curRobot.fIndex + 1
    end
    curRobot.pos = curRobot.pos + curRobot.speed * WIDTH
    if curRobot.pos >= curRobot.max then
        curRobot.DoMove = DoMoveUp
    end
end

DoMoveStatic = function()
    curRobot.fUpdate = bit.bxor(curRobot.fUpdate, 1)
    if curRobot.fUpdate ~= 0 then
        curRobot.fIndex = bit.bxor(curRobot.fIndex, 1)
    end
end

DoMoveArrowLeft = function()
    curRobot.max = curRobot.max - 1
    if curRobot.max == 44 then
        audioPanX = 256
        Audio_Sfx(SFX_ARROW)
    end
    if curRobot.max < 0 then curRobot.max = 255 end
    curRobot.min = curRobot.max * 8
end

DoMoveArrowRight = function()
    curRobot.max = curRobot.max + 1
    if curRobot.max == 244 then
        audioPanX = 0
        Audio_Sfx(SFX_ARROW)
    end
    if curRobot.max > 255 then curRobot.max = 0 end
    curRobot.min = curRobot.max * 8
end

DoMoveMaria = function()
    if minerWilly.y < 96 and minerWilly.air == 0 then
        curRobot.fIndex = 3
    elseif minerWilly.y < 104 and minerWilly.air == 0 then
        curRobot.fIndex = 2
    else
        curRobot.fIndex = bit.rshift(band(gameClockTicks, 2), 1)
    end
end

-- ── Draw functions ───────────────────────────────────────────────────────────

DoDrawRobot = function()
    local frame = band(curRobot.fIndex, curRobot.fMask)
    local gfx   = curRobot.gfx[frame + 1]   -- +1: Lua 1-based
    Video_DrawRobot(curRobot.pos, gfx, curRobot.ink)
end

DoDrawToilet = function()
    local frame = band(curRobot.fIndex, curRobot.fMask)
    local gfx   = curRobot.gfx[frame + 1]
    Video_DrawSprite(curRobot.pos, gfx, 0x0, 0x7)
end

DoDrawArrow = function()
    if curRobot.max < 32 then
        Video_DrawArrow(curRobot.pos + curRobot.min, curRobot.speed)
    end
end

-- ── Robot start definitions ──────────────────────────────────────────────────
-- Now that movement functions are defined we can build the table
-- Level index is 0-based (matching gameLevel)

robotStartDef = {
    [0] = {
        mkRobot(POS(10,48),POS(10,8), POS(10,104),DoMoveDown,  DoDrawRobot,4,robotGfx[36],0x5,2,0,0x3),
        mkRobot(POS(29,56),POS(19,56),POS(29,56), DoMoveLeft,  DoDrawRobot,0,robotGfx[35],0x4,2,0,0x3),
        mkRobot(POS(7,56), POS(7,0),  POS(7,104), DoMoveDown,  DoDrawRobot,2,robotGfx[27],0x2,2,0,0x2),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [1] = {
        mkRobot(POS(8,80), POS(0,80), POS(10,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x2,0,0,0x7),
        mkRobot(POS(20,80),POS(14,80),POS(29,80), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x3,0,4,0x7),
        mkRobot(POS(12,24),POS(12,0), POS(12,96), DoMoveDown,  DoDrawRobot,6,robotGfx[26],0x4,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [2] = {
        mkRobot(POS(16,104),POS(0,104),POS(30,104),DoMoveLeft, DoDrawRobot,0,robotGfx[24],0x6,0,0,0x7),
        mkRobot(POS(14,72), POS(14,48),POS(14,87), DoMoveUp,   DoDrawRobot,3,robotGfx[27],0x3,2,0,0x2),
        mkRobot(POS(27,24), POS(5,24), POS(30,24), DoMoveLeft, DoDrawRobot,0,robotGfx[20],0x2,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [3] = {
        mkRobot(POS(2,32), POS(2,32), POS(2,88),  DoMoveDown,  DoDrawRobot,5,robotGfx[37],0x5,0,0,0x1),
        mkRobot(POS(5,50), POS(5,16), POS(5,80),  DoMoveUp,    DoDrawRobot,6,robotGfx[37],0x5,0,0,0x3),
        mkRobot(POS(8,64), POS(8,19), POS(8,88),  DoMoveDown,  DoDrawRobot,3,robotGfx[37],0x2,0,0,0x3),
        mkRobot(POS(9,104),POS(4,104),POS(14,104),DoMoveLeft,  DoDrawRobot,0,robotGfx[19],0x3,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [4] = {
        mkRobot(POS(18,80),POS(14,80),POS(29,80), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x3,0,4,0x7),
        mkRobot(POS(21,88),POS(16,88),POS(29,88), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x4,0,4,0x7),
        mkRobot(POS(8,64), POS(5,64), POS(29,64), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x6,0,4,0x7),
        mkRobot(POS(20,40),POS(0,40), POS(10,40), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x5,0,4,0x7),
        mkRobot(POS(15,104),POS(10,104),POS(30,104),DoMoveLeft,DoDrawRobot,0,robotGfx[10],0x5,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT()
    },
    [5] = {
        mkRobot(POS(14,64),POS(14,40),POS(14,104),DoMoveDown, DoDrawRobot,1,robotGfx[38],0x4,0,0,0x1),
        mkRobot(POS(11,80),POS(11,44),POS(11,104),DoMoveDown, DoDrawRobot,2,robotGfx[38],0x2,0,0,0x1),
        mkRobot(POS(23,80),POS(23,44),POS(23,104),DoMoveDown, DoDrawRobot,2,robotGfx[38],0x2,0,0,0x1),
        mkRobot(POS(17,48),POS(17,48),POS(17,96), DoMoveDown, DoDrawRobot,4,robotGfx[38],0x6,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [6] = {
        mkRobot(POS(2,48), POS(2,0),  POS(2,88),  DoMoveDown,  DoDrawRobot,1,robotGfx[28],0x4,0,0,0x0),
        mkRobot(POS(4,48), POS(4,0),  POS(4,88),  DoMoveDown,  DoDrawRobot,1,robotGfx[29],0x4,0,0,0x0),
        mkRobot(POS(3,64), POS(3,16), POS(3,104), DoMoveDown,  DoDrawRobot,1,robotGfx[30],0x4,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [7] = {
        mkRobot(POS(16,64),POS(12,64),POS(18,64), DoMoveLeft,  DoDrawRobot,0,robotGfx[10],0x5,0,0,0x3),
        mkRobot(POS(5,88), POS(0,88), POS(11,88), DoMoveRight, DoDrawRobot,0,robotGfx[19],0x3,0,4,0x7),
        mkRobot(POS(0,82), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [8] = {
        mkRobot(POS(2,80), POS(2,64), POS(2,112), DoMoveDown,  DoDrawRobot,2,robotGfx[37],0x3,0,0,0x1),
        mkRobot(POS(5,80), POS(5,64), POS(5,112), DoMoveDown,  DoDrawRobot,2,robotGfx[37],0x3,0,0,0x1),
        mkRobot(POS(8,80), POS(8,64), POS(8,112), DoMoveDown,  DoDrawRobot,2,robotGfx[37],0x3,0,0,0x1),
        mkRobot(POS(6,40), POS(0,40), POS(10,40), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x5,0,4,0x7),
        mkRobot(POS(12,32),POS(12,0), POS(12,104),DoMoveDown,  DoDrawRobot,2,robotGfx[27],0x2,2,0,0x2),
        mkRobot(POS(27,88),POS(16,88),POS(29,88), DoMoveRight, DoDrawRobot,0,robotGfx[33],0x4,0,4,0x7),
        mkRobot(POS(19,24),POS(17,24),POS(30,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[32],0x6,0,0,0x3),
        NOROBOT()
    },
    [9] = {
        mkRobot(POS(30,80),POS(30,64),POS(30,112),DoMoveDown,  DoDrawRobot,2,robotGfx[37],0x3,0,0,0x1),
        mkRobot(POS(7,72), POS(7,64), POS(7,104), DoMoveUp,    DoDrawRobot,2,robotGfx[17],0x2,2,0,0x3),
        mkRobot(POS(19,40),POS(16,40),POS(30,40), DoMoveRight, DoDrawRobot,0,robotGfx[5], 0x6,0,4,0x3),
        mkRobot(POS(14,48),POS(14,0), POS(14,56), DoMoveDown,  DoDrawRobot,1,robotGfx[25],0x5,0,0,0x3),
        mkRobot(POS(0,34), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT()
    },
    [10] = { NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT() },
    [11] = {
        mkRobot(POS(10,48),0,0,      DoMoveStatic, DoDrawRobot,0,robotGfx[14],0x6,0,0,0x1),
        mkRobot(POS(19,24),POS(5,24),POS(30,24),  DoMoveRight, DoDrawRobot,0,robotGfx[20],0x2,0,4,0x7),
        mkRobot(POS(19,80),POS(9,80),POS(17,80),  DoMoveRight, DoDrawRobot,0,robotGfx[33],0x6,0,4,0x7),
        mkRobot(POS(0,34), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        mkRobot(POS(0,11), 208*8,208,DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT()
    },
    [12] = {
        mkRobot(POS(7,40), POS(0,40), POS(10,40), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x5,0,0,0x7),
        mkRobot(POS(8,80), POS(0,80), POS(19,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[32],0x6,0,0,0x3),
        mkRobot(POS(24,24),POS(5,24), POS(30,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[20],0x2,0,0,0x7),
        mkRobot(POS(0,66), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [13] = {
        mkRobot(POS(12,88),POS(12,0), POS(12,104),DoMoveDown,  DoDrawRobot,4,robotGfx[27],0x5,2,0,0x2),
        mkRobot(POS(19,56),POS(14,56),POS(23,56), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x3,0,0,0x7),
        mkRobot(POS(20,80),POS(19,80),POS(30,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[19],0x6,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [14] = {
        mkRobot(POS(4,48), POS(4,48), POS(4,96),  DoMoveDown,  DoDrawRobot,4,robotGfx[39],0x6,2,0,0x1),
        mkRobot(POS(12,64),POS(12,40),POS(12,104),DoMoveDown,  DoDrawRobot,1,robotGfx[39],0x4,0,0,0x1),
        mkRobot(POS(5,32), POS(0,32), POS(9,32),  DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x4,0,0,0x7),
        mkRobot(POS(24,8), POS(24,0), POS(24,16), DoMoveDown,  DoDrawRobot,2,robotGfx[13],0x7,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [15] = {
        mkRobot(POS(5,48), POS(5,48), POS(5,96),  DoMoveDown,  DoDrawRobot,4,robotGfx[38],0x6,2,0,0x1),
        mkRobot(POS(11,80),POS(11,44),POS(11,104),DoMoveDown,  DoDrawRobot,2,robotGfx[38],0x2,0,0,0x1),
        mkRobot(POS(19,32),POS(19,32),POS(19,96), DoMoveDown,  DoDrawRobot,6,robotGfx[38],0x5,0,0,0x1),
        mkRobot(POS(25,64),POS(25,40),POS(25,104),DoMoveDown,  DoDrawRobot,1,robotGfx[38],0x4,0,0,0x1),
        mkRobot(POS(6,32), POS(0,32), POS(9,32),  DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x4,0,0,0x7),
        mkRobot(POS(0,50), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        mkRobot(POS(0,42), 208*8,208,DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT()
    },
    [16] = {
        mkRobot(POS(8,32), POS(0,32), POS(9,32),  DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x4,0,0,0x7),
        mkRobot(POS(0,66), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [17] = {
        mkRobot(POS(5,64), POS(5,40), POS(5,104), DoMoveDown,  DoDrawRobot,1,robotGfx[38],0x4,0,0,0x1),
        mkRobot(POS(11,80),POS(11,40),POS(11,104),DoMoveDown,  DoDrawRobot,2,robotGfx[38],0x2,0,0,0x1),
        mkRobot(POS(19,48),POS(19,48),POS(19,96), DoMoveDown,  DoDrawRobot,4,robotGfx[38],0x6,2,0,0x1),
        mkRobot(POS(25,32),POS(25,32),POS(25,96), DoMoveDown,  DoDrawRobot,6,robotGfx[38],0x5,0,0,0x1),
        mkRobot(POS(0,66), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT()
    },
    [18] = {
        mkRobot(POS(22,104),POS(14,104),POS(24,104),DoMoveRight,DoDrawRobot,0,robotGfx[24],0x5,0,4,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [19] = {
        mkRobot(POS(8,40), POS(4,40), POS(20,40), DoMoveRight, DoDrawRobot,0,robotGfx[18],0x4,0,4,0x7),
        mkRobot(POS(16,40),POS(12,40),POS(28,40), DoMoveRight, DoDrawRobot,0,robotGfx[18],0x6,0,4,0x7),
        mkRobot(POS(11,72),POS(9,72), POS(20,72), DoMoveLeft,  DoDrawRobot,0,robotGfx[18],0x2,0,1,0x7),
        mkRobot(POS(24,72),POS(22,72),POS(27,72), DoMoveRight, DoDrawRobot,0,robotGfx[18],0x7,0,4,0x7),
        mkRobot(POS(7,104),POS(5,104),POS(12,104),DoMoveLeft,  DoDrawRobot,0,robotGfx[18],0x6,0,1,0x7),
        mkRobot(POS(12,104),POS(11,104),POS(18,104),DoMoveLeft,DoDrawRobot,0,robotGfx[18],0x1,0,2,0x7),
        mkRobot(POS(18,104),POS(16,104),POS(23,104),DoMoveLeft,DoDrawRobot,0,robotGfx[18],0x4,0,3,0x7),
        mkRobot(POS(24,104),POS(23,104),POS(30,104),DoMoveLeft,DoDrawRobot,0,robotGfx[18],0x2,0,0,0x7)
    },
    [20] = {
        mkRobot(POS(12,16),POS(12,16),POS(12,48), DoMoveDown,  DoDrawRobot,1,robotGfx[40],0x2,0,0,0x0),
        mkRobot(POS(5,72), POS(5,48), POS(5,87),  DoMoveUp,    DoDrawRobot,3,robotGfx[27],0x3,2,0,0x2),
        mkRobot(POS(7,56), POS(7,48), POS(7,96),  DoMoveDown,  DoDrawRobot,2,robotGfx[27],0x5,2,0,0x2),
        mkRobot(POS(11,75),POS(11,72),POS(11,96), DoMoveDown,  DoDrawRobot,1,robotGfx[27],0x6,2,0,0x3),
        mkRobot(POS(24,80),POS(14,80),POS(29,80), DoMoveRight, DoDrawRobot,2,robotGfx[33],0x3,0,4,0x7),
        NOROBOT(),NOROBOT(),NOROBOT()
    },
    [21] = {
        mkRobot(POS(24,88),POS(16,88),POS(26,88), DoMoveLeft,  DoDrawRobot,0,robotGfx[24],0x3,0,0,0x7),
        mkRobot(POS(14,56),POS(14,48),POS(14,96), DoMoveDown,  DoDrawRobot,2,robotGfx[27],0x5,2,0,0x2),
        mkRobot(POS(6,72), POS(6,48), POS(6,87),  DoMoveUp,    DoDrawRobot,3,robotGfx[27],0x3,2,0,0x2),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [22] = {
        mkRobot(POS(4,24), POS(0,24), POS(11,24), DoMoveRight, DoDrawRobot,0,robotGfx[7], 0x3,0,4,0x3),
        mkRobot(POS(16,24),POS(13,24),POS(21,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[35],0x6,0,0,0x3),
        mkRobot(POS(22,48),POS(12,48),POS(24,48), DoMoveLeft,  DoDrawRobot,0,robotGfx[23],0x7,0,0,0x3),
        mkRobot(POS(4,72), POS(2,72), POS(6,72),  DoMoveRight, DoDrawRobot,0,robotGfx[25],0x2,0,4,0x3),
        mkRobot(POS(22,96),POS(0,96), POS(30,96), DoMoveLeft,  DoDrawRobot,0,robotGfx[10],0x4,0,0,0x3),
        mkRobot(POS(11,80),POS(9,80), POS(17,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        NOROBOT(),NOROBOT()
    },
    [23] = {
        mkRobot(POS(3,32), POS(3,8),  POS(3,104), DoMoveDown,  DoDrawRobot,3,robotGfx[21],0x3,0,0,0x1),
        mkRobot(POS(9,96), POS(9,0),  POS(9,104), DoMoveDown,  DoDrawRobot,2,robotGfx[21],0x6,2,0,0x1),
        mkRobot(POS(15,64),POS(15,0), POS(15,104),DoMoveUp,    DoDrawRobot,4,robotGfx[21],0x4,2,0,0x1),
        mkRobot(POS(20,32),POS(20,8), POS(20,104),DoMoveDown,  DoDrawRobot,3,robotGfx[21],0x3,0,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [24] = {
        mkRobot(POS(9,96), POS(9,0),  POS(9,104), DoMoveDown,  DoDrawRobot,2,robotGfx[21],0x6,2,0,0x1),
        mkRobot(POS(14,64),POS(14,0), POS(14,104),DoMoveUp,    DoDrawRobot,4,robotGfx[21],0x4,2,0,0x1),
        mkRobot(POS(20,96),POS(20,0), POS(20,104),DoMoveDown,  DoDrawRobot,2,robotGfx[21],0x6,2,0,0x1),
        mkRobot(POS(27,32),POS(27,8), POS(27,104),DoMoveDown,  DoDrawRobot,3,robotGfx[21],0x3,0,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [25] = {
        mkRobot(POS(16,104),POS(0,104),POS(24,104),DoMoveLeft, DoDrawRobot,0,robotGfx[34],0x6,0,0,0x7),
        mkRobot(POS(4,72),  POS(0,72), POS(5,72),  DoMoveRight,DoDrawRobot,0,robotGfx[31],0x7,0,4,0x3),
        mkRobot(POS(3,48),  POS(0,48), POS(6,48),  DoMoveRight,DoDrawRobot,0,robotGfx[34],0x4,0,4,0x7),
        mkRobot(POS(8,24),  POS(0,24), POS(9,24),  DoMoveRight,DoDrawRobot,0,robotGfx[31],0x3,0,4,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [26] = {
        mkRobot(POS(3,72), POS(3,0),  POS(3,96),  DoMoveUp,    DoDrawRobot,2,robotGfx[3], 0x2,0,0,0x3),
        mkRobot(POS(7,88), POS(7,0),  POS(7,104), DoMoveDown,  DoDrawRobot,4,robotGfx[27],0x5,2,0,0x2),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [27] = {
        mkRobot(POS(25,48),POS(25,0), POS(25,88), DoMoveDown,  DoDrawRobot,1,robotGfx[28],0x4,0,0,0x0),
        mkRobot(POS(27,48),POS(27,0), POS(27,88), DoMoveDown,  DoDrawRobot,1,robotGfx[29],0x4,0,0,0x0),
        mkRobot(POS(26,64),POS(26,16),POS(26,104),DoMoveDown,  DoDrawRobot,1,robotGfx[30],0x4,2,0,0x1),
        mkRobot(POS(12,96),POS(0,96), POS(15,96), DoMoveLeft,  DoDrawRobot,0,robotGfx[18],0x3,0,0,0x7),
        mkRobot(POS(6,64), POS(6,56), POS(6,80),  DoMoveUp,    DoDrawRobot,1,robotGfx[3], 0x4,2,0,0x3),
        mkRobot(POS(17,76),POS(17,40),POS(17,80), DoMoveDown,  DoDrawRobot,1,robotGfx[2], 0x5,2,0,0x3),
        NOROBOT(),NOROBOT()
    },
    [28] = {
        mkRobot(POS(25,96),POS(24,96),POS(30,96), DoMoveRight, DoDrawRobot,0,robotGfx[18],0x6,0,4,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [29] = {
        mkRobot(POS(8,32), POS(8,0),  POS(8,88),  DoMoveUp,    DoDrawRobot,2,robotGfx[41],0x5,2,0,0x3),
        mkRobot(POS(11,16),POS(11,0), POS(11,104),DoMoveDown,  DoDrawRobot,1,robotGfx[41],0x3,2,0,0x1),
        mkRobot(POS(14,72),POS(14,0), POS(14,96), DoMoveDown,  DoDrawRobot,3,robotGfx[42],0x6,0,0,0x0),
        mkRobot(POS(17,64),POS(17,8), POS(17,104),DoMoveUp,    DoDrawRobot,4,robotGfx[41],0x2,2,0,0x3),
        mkRobot(POS(20,32),POS(20,0), POS(20,80), DoMoveUp,    DoDrawRobot,2,robotGfx[41],0x5,2,0,0x3),
        mkRobot(POS(23,16),POS(23,0), POS(23,104),DoMoveDown,  DoDrawRobot,1,robotGfx[41],0x3,2,0,0x1),
        mkRobot(POS(28,72),POS(28,0), POS(28,96), DoMoveDown,  DoDrawRobot,3,robotGfx[41],0x6,0,0,0x0),
        NOROBOT()
    },
    [30] = {
        mkRobot(POS(10,64),POS(10,56),POS(10,80), DoMoveUp,    DoDrawRobot,1,robotGfx[4], 0x4,2,0,0x3),
        mkRobot(POS(13,48),POS(13,40),POS(13,80), DoMoveDown,  DoDrawRobot,2,robotGfx[2], 0x3,0,0,0x3),
        mkRobot(POS(16,76),POS(16,40),POS(16,80), DoMoveDown,  DoDrawRobot,1,robotGfx[1], 0x5,2,0,0x3),
        mkRobot(POS(22,80),POS(19,80),POS(30,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[19],0x6,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [31] = {
        mkRobot(POS(12,104),POS(5,104),POS(12,104),DoMoveLeft, DoDrawRobot,0,robotGfx[18],0x6,0,1,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [32] = {
        mkRobot(POS(4,48), POS(2,48), POS(7,48),  DoMoveLeft,  DoDrawRobot,0,robotGfx[7], 0x6,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [33] = {
        mkRobot(POS(16,24),POS(0,24), POS(27,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[25],0x4,0,0,0x3),
        mkRobot(POS(28,104),0,0,      DoMoveStatic,DoDrawToilet,0,robotGfx[0], 0xf,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [34] = {
        mkRobot(POS(6,32), POS(6,16), POS(6,104), DoMoveDown,  DoDrawRobot,2,robotGfx[6], 0x7,2,0,0x3),
        mkRobot(POS(12,16),POS(12,16),POS(12,48), DoMoveDown,  DoDrawRobot,1,robotGfx[40],0x2,0,0,0x0),
        mkRobot(POS(16,104),POS(10,104),POS(30,104),DoMoveRight,DoDrawRobot,0,robotGfx[9],0x5,0,4,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [35] = {
        mkRobot(POS(14,88),0,0,       DoMoveMaria, DoDrawRobot,0,robotGfx[43],0x7,0,0,0x3),
        mkRobot(POS(14,88),0,0,       DoMoveMaria, DoDrawRobot,0,robotGfx[44],0x5,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [36] = {
        mkRobot(POS(2,16), POS(0,16), POS(10,16), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        mkRobot(POS(7,48), POS(7,40), POS(7,80),  DoMoveDown,  DoDrawRobot,2,robotGfx[1], 0x3,0,0,0x3),
        mkRobot(POS(0,73), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [37] = {
        mkRobot(POS(20,32),POS(20,0), POS(20,96), DoMoveDown,  DoDrawRobot,4,robotGfx[4], 0x5,2,0,0x3),
        mkRobot(POS(9,72), POS(9,64), POS(9,104), DoMoveUp,    DoDrawRobot,2,robotGfx[17],0x2,2,0,0x3),
        mkRobot(POS(0,66), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [38] = {
        mkRobot(POS(4,48), POS(4,0),  POS(4,88),  DoMoveDown,  DoDrawRobot,1,robotGfx[28],0x4,0,0,0x0),
        mkRobot(POS(6,48), POS(6,0),  POS(6,88),  DoMoveDown,  DoDrawRobot,1,robotGfx[29],0x4,0,0,0x0),
        mkRobot(POS(5,64), POS(5,16), POS(5,104), DoMoveDown,  DoDrawRobot,1,robotGfx[30],0x4,2,0,0x1),
        mkRobot(POS(22,80),POS(8,80), POS(24,80), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x2,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [39] = {
        mkRobot(POS(8,24), POS(5,24), POS(30,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[20],0x2,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [40] = {
        mkRobot(POS(18,72),POS(18,64),POS(18,104),DoMoveUp,    DoDrawRobot,2,robotGfx[17],0x2,2,0,0x3),
        mkRobot(POS(10,96),POS(10,56),POS(10,96), DoMoveUp,    DoDrawRobot,5,robotGfx[37],0x6,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [41] = {
        mkRobot(POS(4,66), POS(4,56), POS(4,88),  DoMoveDown,  DoDrawRobot,2,robotGfx[11],0x3,0,0,0x1),
        mkRobot(POS(6,70), POS(6,56), POS(6,88),  DoMoveDown,  DoDrawRobot,2,robotGfx[11],0x6,0,0,0x1),
        mkRobot(POS(8,74), POS(8,56), POS(8,88),  DoMoveDown,  DoDrawRobot,2,robotGfx[11],0x1,0,0,0x1),
        mkRobot(POS(10,78),POS(10,56),POS(10,88), DoMoveDown,  DoDrawRobot,2,robotGfx[11],0x4,0,0,0x1),
        mkRobot(POS(12,82),POS(12,56),POS(12,88), DoMoveDown,  DoDrawRobot,2,robotGfx[11],0x2,0,0,0x1),
        mkRobot(POS(14,86),POS(14,56),POS(14,88), DoMoveDown,  DoDrawRobot,2,robotGfx[12],0x5,0,0,0x1),
        mkRobot(POS(0,41), 28*8,28,  DoMoveArrowLeft, DoDrawArrow,1,nil,0x0,0,0,0x0),
        mkRobot(POS(0,73), 208*8,208,DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0)
    },
    [42] = {
        mkRobot(POS(4,72), POS(0,72), POS(5,72),  DoMoveRight, DoDrawRobot,0,robotGfx[31],0x7,0,4,0x3),
        mkRobot(POS(16,64),POS(12,64),POS(18,64), DoMoveLeft,  DoDrawRobot,0,robotGfx[9], 0x5,0,0,0x3),
        mkRobot(POS(0,97), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [43] = {
        mkRobot(POS(20,88),POS(17,88),POS(30,88), DoMoveLeft,  DoDrawRobot,0,robotGfx[7], 0x2,0,0,0x3),
        mkRobot(POS(24,40),POS(16,40),POS(30,40), DoMoveRight, DoDrawRobot,0,robotGfx[5], 0x6,0,4,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [44] = {
        mkRobot(POS(20,24),POS(20,0), POS(20,64), DoMoveDown,  DoDrawRobot,2,robotGfx[16],0x5,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [45] = {
        mkRobot(POS(16,88),POS(12,88),POS(29,88), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        mkRobot(POS(18,24),POS(18,0), POS(18,64), DoMoveDown,  DoDrawRobot,2,robotGfx[17],0x5,2,0,0x3),
        mkRobot(POS(22,64),POS(21,64),POS(30,64), DoMoveLeft,  DoDrawRobot,0,robotGfx[8], 0x3,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [46] = {
        mkRobot(POS(4,32), POS(4,0),  POS(4,64),  DoMoveUp,    DoDrawRobot,2,robotGfx[6], 0x5,2,0,0x3),
        mkRobot(POS(13,56),POS(13,48),POS(13,96), DoMoveDown,  DoDrawRobot,2,robotGfx[27],0x5,2,0,0x2),
        mkRobot(POS(19,72),POS(15,72),POS(23,72), DoMoveRight, DoDrawRobot,0,robotGfx[24],0x2,0,4,0x7),
        mkRobot(POS(25,72),POS(25,32),POS(25,80), DoMoveDown,  DoDrawRobot,2,robotGfx[22],0x3,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [47] = {
        mkRobot(POS(5,16), POS(0,16), POS(10,16), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        mkRobot(POS(20,24),POS(18,24),POS(22,24), DoMoveRight, DoDrawRobot,0,robotGfx[35],0x4,0,4,0x3),
        mkRobot(POS(16,24),POS(16,0), POS(16,64), DoMoveDown,  DoDrawRobot,2,robotGfx[17],0x5,2,0,0x3),
        mkRobot(POS(22,96),POS(22,56),POS(22,96), DoMoveUp,    DoDrawRobot,5,robotGfx[37],0x6,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [48] = {
        mkRobot(POS(16,104),POS(7,104),POS(22,104),DoMoveLeft, DoDrawRobot,0,robotGfx[19],0x3,0,0,0x7),
        mkRobot(POS(25,24),POS(0,24),  POS(27,24), DoMoveLeft, DoDrawRobot,0,robotGfx[18],0x3,0,0,0x7),
        mkRobot(POS(9,48), POS(4,48),  POS(27,48), DoMoveRight,DoDrawRobot,0,robotGfx[18],0x6,0,4,0x7),
        mkRobot(POS(19,72),POS(2,72),  POS(27,72), DoMoveLeft, DoDrawRobot,0,robotGfx[18],0x4,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [49] = {
        mkRobot(POS(17,72),POS(11,72),POS(18,72), DoMoveRight, DoDrawRobot,0,robotGfx[32],0x3,0,4,0x3),
        mkRobot(POS(11,56),POS(9,56), POS(30,56), DoMoveLeft,  DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [50] = {
        mkRobot(POS(16,104),POS(7,104),POS(22,104),DoMoveLeft, DoDrawRobot,0,robotGfx[19],0x3,0,0,0x7),
        mkRobot(POS(9,72),  POS(7,72), POS(20,72), DoMoveRight,DoDrawRobot,0,robotGfx[9], 0x6,0,4,0x3),
        mkRobot(POS(20,48), POS(7,48), POS(17,48), DoMoveLeft, DoDrawRobot,0,robotGfx[5], 0x4,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [51] = {
        mkRobot(POS(22,104),POS(10,104),POS(30,104),DoMoveRight,DoDrawRobot,0,robotGfx[10],0x5,0,4,0x3),
        mkRobot(POS(16,48),POS(12,48),POS(24,48),  DoMoveLeft, DoDrawRobot,0,robotGfx[23],0x7,0,0,0x3),
        mkRobot(POS(3,24), POS(3,0),  POS(3,64),   DoMoveDown, DoDrawRobot,2,robotGfx[17],0x5,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [52] = { NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT() },
    [53] = {
        mkRobot(POS(14,32),POS(14,0), POS(14,96), DoMoveDown,  DoDrawRobot,4,robotGfx[3], 0x5,2,0,0x3),
        mkRobot(POS(4,48), 0,0,        DoMoveStatic,DoDrawRobot,0,robotGfx[14],0x6,0,0,0x1),
        mkRobot(POS(9,80), POS(0,80),  POS(10,80), DoMoveLeft, DoDrawRobot,0,robotGfx[33],0x2,0,0,0x7),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [54] = {
        mkRobot(POS(11,32),POS(11,0), POS(11,64), DoMoveUp,    DoDrawRobot,2,robotGfx[6], 0x5,2,0,0x3),
        mkRobot(POS(14,24),POS(14,0), POS(14,80), DoMoveDown,  DoDrawRobot,1,robotGfx[22],0x2,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [55] = {
        mkRobot(POS(19,104),POS(7,104),POS(22,104),DoMoveLeft, DoDrawRobot,0,robotGfx[19],0x3,0,0,0x7),
        mkRobot(POS(20,88), POS(12,88),POS(29,88), DoMoveLeft, DoDrawRobot,0,robotGfx[33],0x6,0,0,0x7),
        mkRobot(POS(0,42),  208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [56] = {
        mkRobot(POS(11,50),POS(11,16),POS(11,80), DoMoveUp,    DoDrawRobot,6,robotGfx[37],0x5,0,0,0x3),
        mkRobot(POS(14,24),POS(14,0), POS(14,80), DoMoveDown,  DoDrawRobot,1,robotGfx[22],0x2,2,0,0x1),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [57] = {
        mkRobot(POS(0,42), 208*8,208, DoMoveArrowRight,DoDrawArrow,0,nil,0x0,0,0,0x0),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [58] = {
        mkRobot(POS(8,104), POS(4,104),POS(14,104),DoMoveLeft, DoDrawRobot,0,robotGfx[19],0x3,0,0,0x7),
        mkRobot(POS(21,72), POS(21,64),POS(21,104),DoMoveUp,   DoDrawRobot,2,robotGfx[16],0x2,2,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
    [59] = {
        mkRobot(POS(23,24),POS(23,24),POS(30,24), DoMoveLeft,  DoDrawRobot,0,robotGfx[35],0x6,0,0,0x3),
        mkRobot(POS(20,104),POS(17,104),POS(30,104),DoMoveLeft,DoDrawRobot,0,robotGfx[7], 0x3,0,0,0x3),
        NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT(),NOROBOT()
    },
}

-- ── Public API ───────────────────────────────────────────────────────────────

function Robots_DrawCheat()
    local pos = LIVES + WIDTH - 24
    Video_DrawRobot(pos, robotGfx[43][1], 0x7)   -- [1] = frame 0 (1-indexed)
    Video_DrawRobot(pos, robotGfx[44][1], 0x5)
end

function Robots_Flush()
    -- Slow down Maria animation for toilet-exit sequence
    robotThis[2].fMask   = 0x3
    robotThis[2].fIndex  = 2
    robotThis[2].fUpdate = 0
end

function Robots_Ticker()
    for i = 1, 8 do
        curRobot = robotThis[i]
        curRobot.DoMove()
    end
end

function Robots_Drawer()
    for i = 1, 8 do
        curRobot = robotThis[i]
        curRobot.DoDraw()
    end
end

function Robots_Init()
    local startList = robotStartDef[gameLevel] or {}
    for i = 1, 8 do
        local s = startList[i]
        if s then
            robotThis[i] = {
                pos     = s.pos,
                min     = s.min,
                max     = s.max,
                DoMove  = s.DoMove,
                DoDraw  = s.DoDraw,
                speed   = s.speed,
                gfx     = s.gfxIdx,      -- already the frame array (or nil for arrows)
                ink     = s.ink,
                fUpdate = s.fUpdate,
                fIndex  = s.fIndex,
                fMask   = s.fMask,
            }
        else
            robotThis[i] = NOROBOT()
        end
    end

    -- Master Bedroom: hide Maria if we're in normal run mode (GM_MARIA triggers her)
    if gameLevel == MASTERBEDROOM and gameMode == GM_MARIA then
        robotThis[1].DoMove = DoNothing
        robotThis[1].DoDraw = DoNothing
        robotThis[2].DoMove = DoNothing
        robotThis[2].DoDraw = DoNothing
    end
end
