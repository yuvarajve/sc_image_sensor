#ifndef SLICEKIT_SUPPORT_H_
#define SLICEKIT_SUPPORT_H_

#define CAS 2
#define CLOCK_DIVIDER 4

/////////////////////////////////////////////////////////////////////////////////////////////////////////

#define SDRAM_A16_SQUARE_TILE 1
#define SDRAM_A16_SQUARE_PORTS(X)   {XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_A16_CIRCLE_TILE 1
#define SDRAM_A16_CIRCLE_PORTS(X)   {XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1I, XS1_PORT_1K, XS1_PORT_1L, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_A16_TRIANGLE_TILE 0
#define SDRAM_A16_TRIANGLE_PORTS(X) {XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1I, XS1_PORT_1K, XS1_PORT_1L, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

//not working
#define SDRAM_A16_STAR_TILE 0
#define SDRAM_A16_STAR_PORTS(X)     {XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}


/////////////////////////////////////////////////////////////////////////////////////////////////////////

#define SDRAM_L16_SQUARE_TILE 1
#define SDRAM_L16_SQUARE_PORTS(X)   {XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_L16_CIRCLE_TILE 1
#define SDRAM_L16_CIRCLE_PORTS(X)   {XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1I, XS1_PORT_1K, XS1_PORT_1L, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_L16_TRIANGLE_TILE 0
#define SDRAM_L16_TRIANGLE_PORTS(X) {XS1_PORT_16B, XS1_PORT_1J, XS1_PORT_1I, XS1_PORT_1K, XS1_PORT_1L, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_L16_STAR_TILE 0
#define SDRAM_L16_STAR_PORTS(X)     {XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

/////////////////////////////////////////////////////////////////////////////////////////////////////////

#define SDRAM_U16_SQUARE_TILE 1
#define SDRAM_U16_SQUARE_PORTS(X)   {XS1_PORT_16A, XS1_PORT_1B, XS1_PORT_1G, XS1_PORT_1C, XS1_PORT_1F, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#define SDRAM_U16_DIAMOND_TILE       #error config not supported

////////////////////////////////////////////////////////////////////////////////////////////////////////
#define SDRAM_XCOREXA_PORTS(X)      {XS1_PORT_16A, XS1_PORT_1C, XS1_PORT_1A, XS1_PORT_1B, XS1_PORT_1D, X, CAS, 128, 16, 8, 12, 2, 64, 4096, CLOCK_DIVIDER}

#endif /* SLICEKIT_SUPPORT_H_ */
