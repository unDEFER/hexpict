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

module hexpict.hyperpixel;

import std.math;
import std.stdio;
import std.conv;
import std.file;

import imaged;

// @Areas
short[50] areas;
byte[11][50] pixareas1;
byte[16][50] pixareas2;
byte[24][50] pixareas3;
byte[20][50] pixareas4;

/*
 * Generates mask of ingoing in areas of hyperpixel
 * of point (x, y) if width of hyperpixel is w
 * and height is h.
 * Generates areas (@Areas) if gen_areas.
 * @HyperPixel @HyperMask
 */
ulong hypermask(int x, int y, int w, int h, bool gen_areas)
{
    struct Point
    {
        int x, y;
    }

    /*        0
     *        oo
     *  11  oooooo 1
     *    oooooooooo
     *10oooooooooooooo 2
     *  oooooooooooooo
     *9 oooooooooooooo 3
     *  oooooooooooooo
     * 8  oooooooooo  4
     *   7  oooooo  5
     *        oo
     *         6
     */

    // @PointsOfHexagon
    Point[12] points;

    points[0] = Point(w/2, 0);
    points[2] = Point(w, cast(int) round(h/4.0));
    points[4] = Point(w, h - cast(int) round(h/4.0));
    points[6] = Point(w/2, h);
    points[8] = Point(0, h - cast(int) round(h/4.0));
    points[10] = Point(0, cast(int) round(h/4.0));

    foreach(p; 0..6)
    {
        int p0 = p*2;
        int p1 = ((p+1)*2) % 12;

        int xx = (points[p0].x + points[p1].x)/2;
        int yy = (points[p0].y + points[p1].y)/2;

        points[1+p*2] = Point(xx, yy);
    }

    // @DividesOfHexagon
    ulong ret;
    foreach(s; 3..7)
    {
        foreach(p; 0..12)
        {
            int p1 = p + s;
            double p05 = (p + p1)/2.0;
            if (p05 >= 12) p05 -= 12;
            p1 = p1 % 12;

            bool bit;
            if (p05 == 0)
            {
                bit = (y < points[p].y);
            }
            else if (p05 == 3)
            {
                bit = (x >= points[p].x);
            }
            else if (p05 == 6)
            {
                bit = (y >= points[p].y);
            }
            else if (p05 == 9)
            {
                bit = (x < points[p].x);
            }
            else
            {
                int dx = points[p1].x - points[p].x;
                int dy = points[p1].y - points[p].y;
                
                double k = 1.0*dy/dx;

                int dx1 = x - points[p].x;
                int dy1 = y - points[p].y;
                if (dx1 == 0)
                {
                    bit = (dy1 == 0);
                }
                else
                {
                    double k1 = 1.0*dy1/dx1;
                    bit = (sgn(dx1) == sgn(dx) && k1 < k);
                }
            }

            if (bit)
                ret |= (1UL << ((s-3)*12 + p));
        }
    }

    /* incircle */
    double cx = w/2;
    double cy = h/2;
    double r2 = cx*cx;
    cx -= .5;
    cy -= .5;

    bool incircle = ( (x-cx)*(x-cx) + (y-cy)*(y-cy) >= r2 );

    if (incircle)
        ret |= (1UL << 48);

    ret |= (1UL << 49);

    // @Areas
    if (gen_areas)
    {
        int pw = w/3;
        int vo = (h-w)/2;

        int px = x/pw;
        int py = (y-vo)/pw;

        int pn1 = 1 + py*3 + px;
        if (y < vo) pn1 = 0;
        else if (py >= 3) pn1 = 10;
        else if (px < 0 || px >= 3 || py < 0 || py >= 3) pn1 = -1;

        int ho = w/2 - pw*2;
        vo = h/2 - pw*2;

        px = (x-ho)/pw;
        py = (y-vo)/pw;

        int pn2 = py*4 + px;
        if (px < 0 || px >= 4 || py < 0 || py >= 4) pn2 = -1;

        pw = w/4;
        vo = (h-w)/2;

        px = x/pw;
        py = (pw+y-vo)/pw;

        int pn3 = py*4 + px;
        if (px < 0 || px >= 4 || py < -1 || py > 5) pn3 = -1;

        vo = (h - pw*3)/2;
        py = (pw+y-vo)/pw;
        //if (w == 24 && x == 12)
        //    writefln("w=%s, pw=%s, y=%s, vo=%s, py=%s", w, pw, y, vo, py);

        int pn4 = py*4 + px;
        if (px < 0 || px >= 4 || py < -1 || py > 4) pn4 = -1;

        foreach (i; 0..49)
        {
            bool r = (ret & (1UL << i)) != 0;
            if (r)
            {
                areas[i]++;

                if (pn1 >= 0)
                {
                    pixareas1[i][pn1]++;
                }
                if (pn2 >= 0)
                {
                    pixareas2[i][pn2]++;
                }
                if (pn3 >= 0)
                {
                    pixareas3[i][pn3]++;
                }
                if (pn4 >= 0)
                {
                    pixareas4[i][pn4]++;
                }
            }
        }

        if (ret)
        {
            areas[49]++;

            if (pn1 >= 0)
            {
                pixareas1[49][pn1]++;
            }
            if (pn2 >= 0)
            {
                pixareas2[49][pn2]++;
            }
            if (pn3 >= 0)
            {
                pixareas3[49][pn3]++;
            }
            if (pn4 >= 0)
            {
                pixareas4[49][pn4]++;
            }
        }
    }

    return ret;
}

/*
 * Generates hyperpixel with width w.
 * Returns false if wasn't generated.
 * @HyperPixel
 */
bool hyperpixel(int w, bool gen_areas)
{
    bool genPixelAreas = (w%3 == 0);
    bool genPixelAreas2 = (w%4 == 0);

    int h = cast(int) round(w * 2.0 / sqrt(3.0));
    int hh = cast(int) round(h/4.0);
    int w5 = cast(int) round(0.5*w);

    // @HyperPixelSuccess
    bool success = (w5 == (w-w5));
    foreach (i; 1..hh+1)
    {
        int ww = cast(int) round(0.5*w*i/hh);
        int ww2 = cast(int) round(0.5*w*(hh-i)/hh);

        success &= (ww == (w5-ww2));
    }

    if (success)
    {
        writefln("Generate hyperpixel %sx%s (%s, %s)", w, h, 1.0*w/h, 1.0*(h-hh)/w);

        // @HyperMask
        ulong[] hpdata = new ulong[w*h];

        foreach (i; hh+1..(h-hh+1))
        {
            foreach(j; 0..w)
            {
                ulong m = hypermask(j, i-1, w, h, gen_areas);
                hpdata[(i-1)*w + j] = m;
            }
        }

        foreach (i; 1..hh+1)
        {
            int ww = cast(int) round(0.5*w*i/hh);

            foreach(j; 0..w5)
            {
                if (w5-j <= ww)
                {
                    ulong m = hypermask(j, i-1, w, h, gen_areas);
                    hpdata[(i-1)*w + j] = m;

                    m = hypermask(j, h-i, w, h, gen_areas);
                    hpdata[(h-i)*w + j] = m;
                }
            }

            foreach(j; 0..(w-w5))
            {
                if (j+1 <= ww)
                {
                    ulong m = hypermask(w5+j, i-1, w, h, gen_areas);
                    hpdata[(i-1)*w + w5+j] = m;

                    m = hypermask(w5+j, h-i, w, h, gen_areas);
                    hpdata[(h-i)*w + w5+j] = m;
                }
            }
        }

        static if (false)
        debug
        {
            foreach(a; 0..50)
            {
                writefln("area %s: %s", a, areas[a]);
                writeln();
                writefln("   %2d", pixareas1[a][0]);
                foreach(j; 0..3)
                {
                    foreach(i; 0..3)
                    {
                        writef("%2d ", pixareas1[a][1+j*3+i]);
                    }
                    writeln();
                }
                writefln("   %2d", pixareas1[a][10]);
                writeln();
                foreach(j; 0..4)
                {
                    foreach(i; 0..4)
                    {
                        writef("%2d ", pixareas2[a][j*4+i]);
                    }
                    writeln();
                }
                writeln();

                writeln();
                foreach(j; 0..6)
                {
                    foreach(i; 0..4)
                    {
                        writef("%2d ", pixareas3[a][j*4+i]);
                    }
                    writeln();
                }
                writeln();
                foreach(j; 0..5)
                {
                    foreach(i; 0..4)
                    {
                        writef("%2d ", pixareas4[a][j*4+i]);
                    }
                    writeln();
                }
                writeln();
            }
        }

        string dir = "/tmp/hexpict/";
        if (!dir.exists) dir.mkdir;

        // @Areas
        if (gen_areas && genPixelAreas)
        {
            string filename = "hp"~w.text~"x"~h.text~"-3.areas";
            
            ubyte[50*2 + 50*11 + 50*16] buffer;
            buffer[0..100] = (cast(ubyte*)&areas)[0..100];
            foreach (i, pa; pixareas1)
            {
                buffer[100+i*11..100+(i+1)*11] = cast(ubyte[]) pa[0..$];
            }
            foreach (i, pa; pixareas2)
            {
                buffer[100+550+i*16..100+550+(i+1)*16] = cast(ubyte[]) pa[0..$];
            }

            std.file.write(dir ~ filename, buffer);
        }

        // @Areas
        if (gen_areas && genPixelAreas2)
        {
            string filename = "hp"~w.text~"x"~h.text~"-4.areas";
            
            ubyte[50*2 + 50*24 + 50*20] buffer;
            buffer[0..100] = (cast(ubyte*)&areas)[0..100];
            foreach (i, pa; pixareas3)
            {
                buffer[100+i*24..100+(i+1)*24] = cast(ubyte[]) pa[0..$];
            }
            foreach (i, pa; pixareas4)
            {
                buffer[100+1200+i*20..100+1200+(i+1)*20] = cast(ubyte[]) pa[0..$];
            }

            std.file.write(dir ~ filename, buffer);
        }

        std.file.write(dir ~ "hp"~w.text~"x"~h.text~".areas", hpdata);
    }

    return success;
}

void scalelist()
{
    // @HyperPixel @HyperPixelSuccess
    writefln("Available hyperpixel sizes:");
    write("3, 4");
    foreach (w; 5..100)
    {
        int h = cast(int) round(w * 2.0 / sqrt(3.0));
        int hh = cast(int) round(h/4.0);
        int w5 = cast(int) round(0.5*w);

        bool success = (w5 == (w-w5));
        foreach (i; 1..hh+1)
        {
            int ww = cast(int) round(0.5*w*i/hh);
            int ww2 = cast(int) round(0.5*w*(hh-i)/hh);

            success &= (ww == (w5-ww2));
        }

        if (success)
        {
            writef(", %s", w);
        }
    }
    
    writeln();
}
