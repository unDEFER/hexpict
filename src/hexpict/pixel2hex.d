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

module hexpict.pixel2hex;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;

import imaged;
import hexpict.h6p;
import hexpict.common;
import hexpict.hyperpixel;

/*
 * Convert `inpict` png-file into `outpict` h6p image
 * with `scale` scaledown
 */
void pixel2hex(string inpict, string outpict, int scale, bool debug_png = false)
{
    IMGError err;
    Image image = load(inpict, err);

    string dir = "/tmp/hexpict/";

    ubyte[] buffer;

    // @Areas @Scale1Notes
    if (scale == 1 || scale == 3)
    {
        string areas_file = dir~"hp24x28-3.areas";
        if (areas_file.exists)
        {
            buffer = cast(ubyte[]) read(areas_file);

            areas[0..$] = (cast(short[]) buffer[0..100])[0..50];
            foreach (i, ref pa; pixareas1)
            {
                pa[0..$] = cast(byte[]) buffer[100+i*11..100+(i+1)*11];
            }
            foreach (i, ref pa; pixareas2)
            {
                pa[0..$] = cast(byte[]) buffer[100+550+i*16..100+550+(i+1)*16];
            }
        }
        else
        {
            hyperpixel(24, true);
        }
    }
    else if (scale == 4)
    {
        string areas_file = dir~"hp24x28-4.areas";
        if (areas_file.exists)
        {
            buffer = cast(ubyte[]) read(areas_file);

            areas[0..$] = (cast(short[]) buffer[0..100])[0..50];
            foreach (i, ref pa; pixareas3)
            {
                pa[0..$] = cast(byte[]) buffer[100+i*24..100+(i+1)*24];
            }
            foreach (i, ref pa; pixareas4)
            {
                pa[0..$] = cast(byte[]) buffer[100+1200+i*20..100+1200+(i+1)*20];
            }
        }
        else
        {
            hyperpixel(24, true);
        }
    }
    else
    {
        assert(false, "scale must be 1, 3 or 4");
    }

    // @AreasChecking
    foreach(a, area; areas)
    {
        int sum;
        
        if (scale == 1 || scale == 3)
        {
            sum = 0;
            foreach(p; pixareas1[a])
            {
                sum += p;
            }
            assert(area == sum);

            sum = 0;
            foreach(p; pixareas2[a])
            {
                sum += p;
            }
            assert(area == sum);
        }
        else if (scale == 4)
        {
            sum = 0;
            foreach(p; pixareas3[a])
            {
                sum += p;
            }
            assert(area == sum);

            sum = 0;
            foreach(p; pixareas4[a])
            {
                sum += p;
            }
            assert(area == sum);
        }
    }

    int iw = image.width;
    int ih = image.height;

    double ws, hs, mo;
    if (scale == 1)
    {
        ws = 1.0;
        hs = 5.0/6;
        mo = 0;
    }
    else if (scale == 3)
    {
        ws = 3.0;
        hs = 2.5;
        mo = 1.0;
    }
    else if (scale == 4)
    {
        ws = 4.0;
        hs = 3.5;
        mo = 1.5;
    }

    int nw = cast(int) (iw/ws);
    int nh = cast(int) (ih/hs);

    ubyte[] imgdata = new ubyte[nw*nh*3];
    ubyte[] aimgdata = new ubyte[nw*nh*3];
    ubyte[] maskdata = new ubyte[nw*nh*3];

    // @GenerateAreaMasks
    foreach (y; 0..nh)
    {
        writef("\r(pixel2hex) %s / %s", y, nh);
        stdout.flush();
        double iy = mo + y*hs;

        foreach (x; 0..nw)
        {
            double ix;
            if (y%2 == 0)
                ix = mo + x*ws;
            else
                ix = mo + ws/2 + x*ws;

            Pixel[117] aps;
            Pixel[117] bps;
            double[117] av_d;

            int x0, y0;

            // @H6PMask
            mask:
            foreach (ubyte i; 0..117)
            {
                int area = 0;
                // @PixArea
                byte[24] pixarea;

                int r, g, b;
                int ar, ag, ab;

                ubyte[4] nareas;
                int na = 0;

                if (i == 0)
                {
                    nareas[0] = 49;
                    na = 1;
                }
                else
                {
                    i--;
                    if (i >= 0 && i < 48)
                    {
                        nareas[0] = i;
                        na = 1;
                    }
                    else if (i >= 48 && i < 60)
                    {
                        nareas[0] = cast(ubyte)(i-48);
                        nareas[1] = cast(ubyte)((i-48 + 6)%12);
                        na = 2;
                    }
                    else if (i >= 60 && i < 72)
                    {
                        nareas[0] = cast(ubyte)(i-60);
                        nareas[1] = cast(ubyte)(24 + (i-60 + 5)%12);
                        na = 2;
                    }
                    else if (i >= 72 && i < 75)
                    {
                        nareas[0] = cast(ubyte)(i-72);
                        nareas[1] = cast(ubyte)((i-72 + 3)%12);
                        nareas[2] = cast(ubyte)((i-72 + 6)%12);
                        nareas[3] = cast(ubyte)((i-72 + 9)%12);
                        na = 4;
                    }
                    else if (i >= 75 && i < 87)
                    {
                        ubyte j = cast(ubyte)(i - 75);
                        nareas[0] = cast(ubyte)(12 + j);
                        nareas[1] = cast(ubyte)(12 + (j + 4)%12);
                        na = 2;
                    }
                    else if (i >= 87 && i < 93)
                    {
                        ubyte j = cast(ubyte)(i - 87);
                        nareas[0] = cast(ubyte)(12 + j);
                        nareas[1] = cast(ubyte)(12 + (j + 6)%12);
                        na = 2;
                    }
                    else if (i >= 93 && i < 105)
                    {
                        ubyte j = cast(ubyte)(i - 93);
                        nareas[0] = cast(ubyte)(12 + (j%6)*2);
                        nareas[1] = cast(ubyte)(36 + ((j%6)*2 + 4 + (j/6)*2)%12);
                        na = 2;
                    }
                    else if (i >= 105 && i < 109)
                    {
                        nareas[0] = cast(ubyte)(12 + (i-105));
                        nareas[1] = cast(ubyte)(12 + (i-105 + 4)%12);
                        nareas[2] = cast(ubyte)(12 + (i-105 + 8)%12);
                        na = 3;
                    }
                    else if (i == 109)
                    {
                        nareas[0] = 48;
                        na = 1;
                    }
                    i++;
                }

                foreach (d; nareas[0..na])
                {
                    if (scale == 1 || scale == 3)
                    {
                        if (y%2 == 0)
                        {
                            foreach (dn; 0..11)
                            {
                                pixarea[dn] += pixareas1[d][dn];
                            }

                            area += areas[d];
                        }
                        else
                        {
                            foreach (dn; 0..16)
                            {
                                pixarea[dn] += pixareas2[d][dn];
                            }

                            area += areas[d];
                        }
                    }
                    else if (scale == 4)
                    {
                        if (y%2 == 0)
                        {
                            foreach (dn; 0..24)
                            {
                                pixarea[dn] += pixareas3[d][dn];
                            }

                            area += areas[d];
                        }
                        else
                        {
                            foreach (dn; 0..20)
                            {
                                pixarea[dn] += pixareas4[d][dn];
                            }

                            area += areas[d];
                        }
                    }
                }

                // @Scale1Notes
                if (scale == 1)
                {
                    if (y%2 == 0)
                    {
                        double dx0 = ix-0.333;
                        double dy0 = iy-0.333;

                        x0 = cast(int) round(ix-0.333);
                        y0 = cast(int) round(iy-0.333);

                        foreach (dy; 0..3)
                        {
                            foreach (dx; 0..3)
                            {
                                int xx = cast(int) round(dx0+dx/3.0);
                                int yy = cast(int) round(dy0+dy/3.0);
                                if (xx >= iw || yy >= ih) continue;

                                int dn = 1 + dy*3 + dx;
                                Pixel p = image[xx, yy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas1[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }

                        int xx = cast(int) round(dx0+1/3.0);
                        int yy = cast(int) round(dy0-1/3.0);
                        if (xx < iw && yy > 0)
                        {
                            Pixel p = image[xx, yy];

                            byte pa = pixarea[0];
                            byte a = cast(byte) (pixareas1[49][0] - pa);
                            if (i == 0) a = pa;

                            r += pa * p.r;
                            g += pa * p.g;
                            b += pa * p.b;

                            ar += a * p.r;
                            ag += a * p.g;
                            ab += a * p.b;
                        }

                        xx = cast(int) round(dx0+1/3.0);
                        yy = cast(int) round(dy0+1);
                        if (xx < iw && yy < ih)
                        {
                            Pixel p = image[xx, yy];

                            byte pa = pixarea[10];
                            byte a = cast(byte) (pixareas1[49][10] - pa);
                            if (i == 0) a = pa;

                            r += pa * p.r;
                            g += pa * p.g;
                            b += pa * p.b;

                            ar += a * p.r;
                            ag += a * p.g;
                            ab += a * p.b;
                        }
                    }
                    else
                    {
                        double dx0 = ix-0.5;
                        double dy0 = iy-0.5;
                        x0 = cast(int) round(ix-0.5);
                        y0 = cast(int) round(iy-0.5);

                        foreach (dy; 0..4)
                        {
                            foreach (dx; 0..4)
                            {
                                int xx = cast(int) round(dx0+dx/3.0);
                                int yy = cast(int) round(dy0+dy/3.0);
                                if (xx >= iw || yy >= ih) continue;

                                int dn = dy*4 + dx;
                                Pixel p = image[xx, yy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas2[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }
                    }
                }
                else if (scale == 3)
                {
                    // @Scale3_4Notes
                    if (y%2 == 0)
                    {
                        x0 = cast(int) round(ix)-1;
                        y0 = cast(int) round(iy)-1;

                        foreach (dy; 0..3)
                        {
                            foreach (dx; 0..3)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                int dn = 1 + dy*3 + dx;
                                Pixel p = image[x0+dx, y0+dy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas1[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }

                        if (x0+1 < iw && y0-1 > 0)
                        {
                            Pixel p = image[x0+1, y0-1];

                            byte pa = pixarea[0];
                            byte a = cast(byte) (pixareas1[49][0] - pa);
                            if (i == 0) a = pa;

                            r += pa * p.r;
                            g += pa * p.g;
                            b += pa * p.b;

                            ar += a * p.r;
                            ag += a * p.g;
                            ab += a * p.b;
                        }

                        if (x0+1 < iw && y0+3 < ih)
                        {
                            Pixel p = image[x0+1, y0+3];

                            byte pa = pixarea[10];
                            byte a = cast(byte) (pixareas1[49][10] - pa);
                            if (i == 0) a = pa;

                            r += pa * p.r;
                            g += pa * p.g;
                            b += pa * p.b;

                            ar += a * p.r;
                            ag += a * p.g;
                            ab += a * p.b;
                        }
                    }
                    else
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-1.5);

                        foreach (dy; 0..4)
                        {
                            foreach (dx; 0..4)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                int dn = dy*4 + dx;
                                Pixel p = image[x0+dx, y0+dy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas2[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }
                    }
                }
                else if (scale == 4)
                {
                    // @Scale3_4Notes
                    if (y%2 == 0)
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-2.5);

                        foreach (dy; 0..6)
                        {
                            foreach (dx; 0..4)
                            {
                                if (y0+dy < 0 || x0+dx >= iw || y0+dy >= ih) continue;

                                int dn = dy*4 + dx;
                                Pixel p = image[x0+dx, y0+dy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas3[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }
                    }
                    else
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-2.0);

                        foreach (dy; 0..5)
                        {
                            foreach (dx; 0..4)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                int dn = dy*4 + dx;
                                Pixel p = image[x0+dx, y0+dy];

                                byte pa = pixarea[dn];
                                byte a = cast(byte) (pixareas4[49][dn] - pa);
                                if (i == 0) a = pa;

                                r += pa * p.r;
                                g += pa * p.g;
                                b += pa * p.b;

                                ar += a * p.r;
                                ag += a * p.g;
                                ab += a * p.b;
                            }
                        }
                    }
                }

                if (area > 0)
                {
                    r /= area;
                    g /= area;
                    b /= area;
                }

                if (area < areas[49])
                {
                    ar /= areas[49] - area;
                    ag /= areas[49] - area;
                    ab /= areas[49] - area;
                }
                else if (i == 0)
                {
                    ar /= area;
                    ag /= area;
                    ab /= area;
                }

                Pixel ap = Pixel(r, g, b, 255);
                Pixel bp = Pixel(ar, ag, ab, 255);
                //if (ar == 0 && ag == 0 && ab == 0)
                //    writefln("%sx%s: %X %s, %s: %s < %s", x, y, i, ap, bp, area, areas[49]);

                aps[i] = ap;
                bps[i] = bp;
                av_d[i] = dist(ap, bp);
            }

            ubyte m;

            int max_d;
            double max_dist = 0.0;

            foreach (int d, av; av_d)
            {
                if (av > max_dist)
                {
                    max_d = d;
                    max_dist = av;
                }
            }

            if (max_dist < 1.0)
            {
                m = 0;
                max_d = 0;
            }
            else
            {
                m = cast(ubyte) max_d;
            }

            Pixel ap = bps[max_d];
            Pixel dp = aps[max_d];
                                /*if (abs(x - 42) <= 0 && abs(y - 6) <= 0)
                                {
                                    writefln("%sx%s (%sx%s): ap=%s dp=%s m=%s", x0, y0, x, y, ap, dp, m);
                                    writefln("dist %s", av_d);
                                    writefln("base %s, %s", aps[m], aps[6]);
                                    writefln("compl %s, %s", bps[m], bps[6]);
                                }*/
            if (y0 < 0) y0 = 0;
            Pixel p = image[x0, y0];
            Pixel sp = image[x0, y0];

            //writefln("%sx%s: %X %s, %s", x, y, m, ap, dp);

            double pd = dist(ap, p);
            double spd = dist(ap, p);

            // @OnlyImageColorsMode
            static if (false)
            if (pd > 0.5)
            {
                if (scale == 1)
                {
                    if (y%2 == 0)
                    {
                        x0 = cast(int) round(ix-0.333);
                        y0 = cast(int) round(iy-0.333);

                        foreach (dy; 0..3)
                        {
                            foreach (dx; 0..3)
                            {
                                int xx = cast(int) round(x0+dx/3.0);
                                int yy = cast(int) round(y0+dy/3.0);
                                if (xx >= iw || yy >= ih) continue;

                                Pixel pp = image[xx, yy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }

                        int xx = cast(int) round(x0+1/3.0);
                        int yy = cast(int) round(y0-1/3.0);
                        if (xx < iw && yy > 0)
                        {
                            Pixel pp = image[xx, yy];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }

                        xx = cast(int) round(x0+1/3.0);
                        yy = cast(int) round(y0+1);
                        if (xx < iw && yy < ih)
                        {
                            Pixel pp = image[xx, yy];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }
                    }
                    else
                    {
                        x0 = cast(int) round(ix-0.5);
                        y0 = cast(int) round(iy-0.5);

                        foreach (dy; 0..4)
                        {
                            foreach (dx; 0..4)
                            {
                                int xx = cast(int) round(x0+dx/3.0);
                                int yy = cast(int) round(y0+dy/3.0);
                                if (xx >= iw || yy >= ih) continue;

                                Pixel pp = image[xx, yy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }
                    }
                }
                else if (scale == 3)
                {
                    if (y%2 == 0)
                    {
                        x0 = cast(int) round(ix)-1;
                        y0 = cast(int) round(iy)-1;

                        foreach (dy; 0..3)
                        {
                            foreach (dx; 0..3)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                Pixel pp = image[x0+dx, y0+dy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }

                        if (x0+1 < iw && y0-1 > 0)
                        {
                            Pixel pp = image[x0+1, y0-1];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }

                        if (x0+1 < iw && y0+3 < ih)
                        {
                            Pixel pp = image[x0+1, y0+3];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }
                    }
                    else
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-1.5);

                        foreach (dy; 0..4)
                        {
                            foreach (dx; 0..4)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                Pixel pp = image[x0+dx, y0+dy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }
                    }
                }
                else if (scale == 4)
                {
                    if (y%2 == 0)
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-2.5);

                        foreach (dy; 0..6)
                        {
                            foreach (dx; 0..4)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                Pixel pp = image[x0+dx, y0+dy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }

                        if (x0+1 < iw && y0-1 > 0)
                        {
                            Pixel pp = image[x0+1, y0-1];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }

                        if (x0+1 < iw && y0+3 < ih)
                        {
                            Pixel pp = image[x0+1, y0+3];
                            double ppd = dist(ap, pp);
                            if (ppd < pd - 16.0)
                            {
                                p = pp;
                                pd = ppd;
                            }
                        }
                    }
                    else
                    {
                        x0 = cast(int) round(ix-1.5);
                        y0 = cast(int) round(iy-2.0);

                        foreach (dy; 0..5)
                        {
                            foreach (dx; 0..4)
                            {
                                if (x0+dx >= iw || y0+dy >= ih) continue;

                                Pixel pp = image[x0+dx, y0+dy];
                                double ppd = dist(ap, pp);
                                if (ppd < pd - 16.0)
                                {
                                    p = pp;
                                    pd = ppd;
                                }
                            }
                        }
                    }
                }

                //if (sp != p)
                //    writefln("%sx%s %s => %s (%s => %s)", x, y, sp, p, spd, pd);
            }

            imgdata[(y*nw + x)*3 + 0] = cast(ubyte) ap.r;
            imgdata[(y*nw + x)*3 + 1] = cast(ubyte) ap.g;
            imgdata[(y*nw + x)*3 + 2] = cast(ubyte) ap.b;

            aimgdata[(y*nw + x)*3 + 0] = cast(ubyte) dp.r;
            aimgdata[(y*nw + x)*3 + 1] = cast(ubyte) dp.g;
            aimgdata[(y*nw + x)*3 + 2] = cast(ubyte) dp.b;

            maskdata[(y*nw + x)*3 + 0] = m;
        }
    }

    writeln();

    Image img = new Img!(Px.R8G8B8)(nw, nh, imgdata);
    Image aimg = new Img!(Px.R8G8B8)(nw, nh, aimgdata);
    Image mask = new Img!(Px.R8G8B8)(nw, nh, maskdata);

    // @GenerateColorMasks
    foreach (y; 0..nh)
    {
        double iy = 1.0+y*2.5;

        foreach (x; 0..nw)
        {
            double ix;
            if (y%2 == 0)
                ix = 1+x*3;
            else
                ix = 2.5+x*3;

            Pixel m0 = mask[x, y];
            if (m0.r == 0) continue;

            Point[6] neigh;

            neigh[5].x = x - 1;
            neigh[5].y = y;

            neigh[2].x = x + 1;
            neigh[2].y = y;

            neigh[0].y = y - 1;
            neigh[1].y = y - 1;

            neigh[4].y = y + 1;
            neigh[3].y = y + 1;

            if (y%2 == 0)
            {
                neigh[0].x = neigh[4].x = x - 1;
                neigh[1].x = neigh[3].x = x;
            }
            else
            {
                neigh[0].x = neigh[4].x = x;
                neigh[1].x = neigh[3].x = x + 1;
            }

            Pixel p0 = img[x, y];
            Pixel p1 = aimg[x, y];

            Pixel[7] np;

            foreach(i, ref n; np[1..7])
            {
                if (neigh[i].x >= 0 && neigh[i].x < nw &&
                        neigh[i].y >= 0 && neigh[i].y < nh)
                    n = img[neigh[i].x, neigh[i].y];
                else
                    n = p0;
            }

            np[0] = p0;

            ubyte m;
            double min_dist = double.max;
            foreach(ubyte s; 1..128)
            {
                Pixel ap = mix(np, s);
                double md = dist(ap, p1);
                if (md < min_dist)
                {
                    m = s;
                    min_dist = md;
                }
            }

            if (min_dist > dist(p0, p1))
            {
                maskdata[(y*nw + x)*3 + 0] = 0;
            }

            maskdata[(y*nw + x)*3 + 1] = m;
        }
    }

    if (debug_png)
    {
        img.write("debug_hex.png");
        mask.write("debug_mask.png");
    }

    write_h6p(img, mask, outpict);
}
