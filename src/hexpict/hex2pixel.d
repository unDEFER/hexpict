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

module hexpict.hex2pixel;

import std.stdio;
import std.file;
import std.math;
import std.conv;
import std.algorithm;

import hexpict.h6p;
import hexpict.common;
import hexpict.hyperpixel;
import imaged;

/*
 * Renders `inpict` h6p-file as `outpict` png image
 * with `scale` hyperpixel
 */
void hex2pixel(string inpict, string outpict, int scale)
{
    IMGError err;
    ulong[] hp;
    Image image, mask;
    read_h6p(inpict, image, mask);

    ubyte[] buffer;

    string dir = "/tmp/hexpict/";

    // @Areas
    if (scale == 3)
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
        // @HyperMask
        int w = scale;
        int h = cast(int) round(w * 2.0 / sqrt(3.0));

        string hpfile = dir ~ "hp"~w.text~"x"~h.text~".areas";
        if (!hpfile.exists)
        {
            if ( !hyperpixel(w, false) )
            {
                assert(false, "Invalid scale " ~ scale.text);
            }
        }

        buffer = cast(ubyte[]) read(hpfile);
        hp = cast(ulong[]) buffer;
    }

    int iw = image.width;
    int ih = image.height;

    int nw, nh;
    int hpw, hph, hh;

    if (scale == 3)
    {
        nw = cast(int) (3*iw);
        nh = cast(int) (2.5*ih+1);
    }
    else if (scale == 4)
    {
        nw = cast(int) (4*iw);
        nh = cast(int) (3.5*ih+1);
    }
    else if (scale == 20)
    {
        hpw = scale;
        hph = cast(int) round(hpw * 2.0 / sqrt(3.0));

        hh = cast(int) round(hph/4.0);

        nw = cast(int) (hpw*iw);
        nh = cast(int) ((hph-hh)*ih+hh+1);
    }

    ubyte[] imgdata = new ubyte[nw*nh*3];
    ushort[] imgdata16;
    if (scale == 3 || scale == 4)
    {
        imgdata16 = new ushort[nw*nh*4];
    }

    foreach (y; 0..ih)
    {
        writef("\r(hex2pixel) %s / %s", y, ih);
        stdout.flush();
        int iy;
        if (scale == 3)
        {
            iy = cast(int) (2.5*y);
        }
        else if (scale == 4)
        {
            iy = cast(int) (3.5*y);
        }
        else if (scale == 20)
        {
            iy = (hph-hh)*y;
        }

        foreach (x; 0..iw)
        {
            Pixel p = image[x, y];
            Pixel m = mask[x, y];

            // @Neighbours
            Point[6] neigh;

            neigh[5].x = x - 1;
            neigh[5].y = y;

            neigh[2].x = x + 1;
            neigh[2].y = y;

            neigh[0].y = y - 1;
            neigh[1].y = y - 1;

            neigh[4].y = y + 1;
            neigh[3].y = y + 1;

            int ix;
            if (y%2 == 0)
            {
                if (scale == 3)
                {
                    ix = cast(int) (3.0*x);
                }
                else if (scale == 4)
                {
                    ix = cast(int) (4.0*x);
                }
                else if (scale == 20)
                {
                    ix = hpw*x;
                }
                neigh[0].x = neigh[4].x = x - 1;
                neigh[1].x = neigh[3].x = x;
            }
            else
            {
                if (scale == 3)
                {
                    ix = cast(int) (3.0*x);
                }
                else if (scale == 4)
                {
                    ix = cast(int) (2.0+4.0*x);
                }
                else if (scale == 20)
                {
                    ix = hpw/2+hpw*x;
                }
                neigh[0].x = neigh[4].x = x;
                neigh[1].x = neigh[3].x = x + 1;
            }

            // @MixNeighbours
            Pixel[7] np;

            foreach(i, ref n; np[1..7])
            {
                if (neigh[i].x >= 0 && neigh[i].x < iw &&
                        neigh[i].y >= 0 && neigh[i].y < ih)
                    n = image[neigh[i].x, neigh[i].y];
                else
                    n = p;
            }

            np[0] = p;

            /*if (x == 4 && y == 6)
            {
                writefln("x=%s, y=%s, p=%s, np[5]=%s, m=%s", x, y, p, np[5], m.r);
            }*/

            // @PixArea
            byte[24] pixarea;
            if (scale == 3 || scale == 4)
            {
                int area = 0;

                ubyte i = cast(ubyte) m.r;

                ubyte[4] nareas;
                int na = 0;

                // @H6PMask
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
                    if (scale == 3)
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
            }

            if (scale == 3)
            {
                // @SmallScaleNotes
                if (y%2 == 0)
                {
                    foreach (dy; 0..3)
                    {
                        foreach (dx; 0..3)
                        {
                            if (ix+dx >= nw || iy+dy >= nh) continue;

                            int dn = 1 + dy*3 + dx;

                            Pixel ap = p;
                            Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas1[49][dn] - pa);

                            int r, g, b;

                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;

                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 3] += pa+a;
                        }
                    }

                    if (ix+1 < nw && iy-1 > 0)
                    {
                        int dn = 0;

                        Pixel ap = p;
                        Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                        byte pa = pixarea[dn];
                        byte a = cast(byte) (pixareas1[49][dn] - pa);

                        int r, g, b;
                        r = pa * mp.r;
                        g = pa * mp.g;
                        b = pa * mp.b;

                        r += a * ap.r;
                        g += a * ap.g;
                        b += a * ap.b;

                        imgdata16[((iy-1)*nw + ix+1)*4 + 0] += r;
                        imgdata16[((iy-1)*nw + ix+1)*4 + 1] += g;
                        imgdata16[((iy-1)*nw + ix+1)*4 + 2] += b;
                        imgdata16[((iy-1)*nw + ix+1)*4 + 3] += pa+a;
                    }

                    if (ix+1 < nw && iy+3 < nh)
                    {
                        int dn = 10;

                        Pixel ap = p;
                        Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                        byte pa = pixarea[dn];
                        byte a = cast(byte) (pixareas1[49][dn] - pa);

                        int r, g, b;
                        r = pa * mp.r;
                        g = pa * mp.g;
                        b = pa * mp.b;

                        r += a * ap.r;
                        g += a * ap.g;
                        b += a * ap.b;

                        imgdata16[((iy+3)*nw + ix+1)*4 + 0] += r;
                        imgdata16[((iy+3)*nw + ix+1)*4 + 1] += g;
                        imgdata16[((iy+3)*nw + ix+1)*4 + 2] += b;
                        imgdata16[((iy+3)*nw + ix+1)*4 + 3] += pa+a;
                    }
                }
                else
                {
                    foreach (dy; 0..4)
                    {
                        foreach (dx; 0..4)
                        {
                            if (ix+dx >= nw || iy+dy >= nh) continue;

                            int dn = dy*4 + dx;

                            Pixel ap = p;
                            Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas2[49][dn] - pa);

                            int r, g, b;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;
                            //writefln("%sx%s: %sx%s, %s*%s + %s*%s",
                            //        x, y, dx, dy, pa, mp, a, p);

                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 3] += pa+a;
                        }
                    }
                }
            }
            else if (scale == 4)
            {
                // @SmallScaleNotes
                if (y%2 == 0)
                {
                    foreach (dy; 0..6)
                    {
                        foreach (dx; 0..4)
                        {
                            if (iy+dy < 0 || ix+dx >= nw || iy+dy >= nh) continue;

                            int dn = dy*4 + dx;

                            Pixel ap = p;
                            Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas3[49][dn] - pa);

                            int r, g, b;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;

                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 3] += pa+a;
                        }
                    }
                }
                else
                {
                    foreach (dy; 0..5)
                    {
                        foreach (dx; 0..4)
                        {
                            if (iy+dy < 0 || ix+dx >= nw || iy+dy >= nh) continue;

                            int dn = dy*4 + dx;

                            Pixel ap = p;
                            Pixel mp = (m.g == 0 ? p : mix(np, cast(ubyte) m.g));

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas4[49][dn] - pa);

                            int r, g, b;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;

                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*4 + 3] += pa+a;
                        }
                    }
                }
            }
            else
            {
                // @BigScaleNotes
                ubyte i = cast(ubyte) m.r;

                ubyte[4] nareas;
                int na = 0;

                // @H6PMask
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
                /*
                if (x == 239 && y == 125)
                {
                    writefln("%sx%s: na=%s, nareas[]=%s", x, y, na, nareas[0..na]);
                }*/

                foreach (dy; 0..hph)
                {
                    foreach (dx; 0..hpw)
                    {
                        if (hp[dx + dy*hpw] & (1UL << 49))
                        {
                            Pixel mp = p;

                            //static if (false)
                            if (i > 0)
                            {
                                foreach (d; nareas[0..na])
                                {
                                    if (hp[dx + dy*hpw] & (1UL << d))
                                    {
                                        mp = mix(np, cast(ubyte) m.g);
                                    }
                                }
                            }

                            imgdata[((iy+dy)*nw + ix+dx)*3 + 0] = cast(ubyte) mp.r;
                            imgdata[((iy+dy)*nw + ix+dx)*3 + 1] = cast(ubyte) mp.g;
                            imgdata[((iy+dy)*nw + ix+dx)*3 + 2] = cast(ubyte) mp.b;
                        }
                    }
                }
            }
        }
    }

    writeln();

    // @SmallScaleNotes
    if (scale == 3 || scale == 4)
    {
        foreach (i; 0 .. imgdata16.length/4)
        {
            ushort c = imgdata16[i*4+3];
            if (c > 0)
            {
                imgdata[i*3+0] = cast(ubyte) (imgdata16[i*4+0] / c);
                imgdata[i*3+1] = cast(ubyte) (imgdata16[i*4+1] / c);
                imgdata[i*3+2] = cast(ubyte) (imgdata16[i*4+2] / c);
            }
        }
    }

    writefln("Writing image");
    Image myImg = new Img!(Px.R8G8B8)(nw, nh, imgdata);
    myImg.write(outpict);
}
