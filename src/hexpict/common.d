/*
 * This is detail documentated program.
 * The idea of detail documentation is that always easy to explain
 * what does function do, but to understand how it does it necessary
 * to know many details. "The devil is in the details."
 * So in the code we are writing description of functions
 * and make references to details like @Detail_Name.
 * All details explained in the "details" directory.
 * We can reference to any detail several times.
 * We don't translate comments in the code, but we can
 * want to translate details to several languages.
 */

module hexpict.common;

import std.math;

import imaged;

struct Point
{
    int x, y;
}

/*
 * Mix 2 colors p1 and p2 in RGB color space
 */
Pixel mix(Pixel p1, Pixel p2)
{
    Pixel p;
    p.r = (p1.r + p2.r)/2;
    p.g = (p1.g + p2.g)/2;
    p.b = (p1.b + p2.b)/2;

    return p;
}

/*
 * Mix 3 colors p1, p2 and p3 in RGB color space
 */
Pixel mix(Pixel p1, Pixel p2, Pixel p3)
{
    Pixel p;
    p.r = (p1.r + p2.r + p3.r)/3;
    p.g = (p1.g + p2.g + p3.g)/3;
    p.b = (p1.b + p2.b + p3.b)/3;

    return p;
}

/*
 * Choose color
 */
Pixel mix(Pixel[6] ps, ubyte m)
{
    return ps[m & 0x7];
}

/*
 * Color distance between 2 colors p1 and p2
 * in RGB color space. See hexpict.color module
 * for color distance in ITP color space.
 */
double dist(Pixel p1, Pixel p2)
{
    int dr = (p1.r - p2.r);
    int dg = (p1.g - p2.g);
    int db = (p1.b - p2.b);

    return sqrt(1.0*dr*dr + dg*dg + db*db);
}

