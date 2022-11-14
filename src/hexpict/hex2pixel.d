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

            areas[0..$] = (cast(short[]) buffer[0..AREAS*2])[0..AREAS];
            foreach (i, ref pa; pixareas1)
            {
                pa[0..$] = cast(byte[]) buffer[AREAS*2+i*11..AREAS*2+(i+1)*11];
            }
            foreach (i, ref pa; pixareas2)
            {
                pa[0..$] = cast(byte[]) buffer[AREAS*2+AREAS*11+i*16..AREAS*2+AREAS*11+(i+1)*16];
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

            areas[0..$] = (cast(short[]) buffer[0..AREAS*2])[0..AREAS];
            foreach (i, ref pa; pixareas3)
            {
                pa[0..$] = cast(byte[]) buffer[AREAS*2+i*24..AREAS*2+(i+1)*24];
            }
            foreach (i, ref pa; pixareas4)
            {
                pa[0..$] = cast(byte[]) buffer[AREAS*2+AREAS*24+i*20..AREAS*2+AREAS*24+(i+1)*20];
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
    else
    {
        hpw = scale;
        hph = cast(int) round(hpw * 2.0 / sqrt(3.0));

        hh = cast(int) round(hph/4.0);

        nw = cast(int) (hpw*iw);
        nh = cast(int) ((hph-hh)*ih+hh+1);
    }

    ubyte[] imgdata = new ubyte[nw*nh*4];
    ushort[] imgdata16;
    if (scale == 3 || scale == 4)
    {
        imgdata16 = new ushort[nw*nh*5];
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
        else
        {
            iy = (hph-hh)*y;
        }

        foreach (x; 0..iw)
        {
            Pixel p = image[x, y];
            Pixel m = mask[x, y];

            // @Neighbours
            Point[6] neigh = neighbours(x, y);

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
                else
                {
                    ix = hpw*x;
                }
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
                else
                {
                    ix = hpw/2+hpw*x;
                }
            }

            // @MixNeighbours
            Pixel[6] np;

            foreach(i, ref n; np)
            {
                if (neigh[i].x >= 0 && neigh[i].x < iw &&
                        neigh[i].y >= 0 && neigh[i].y < ih)
                    n = image[neigh[i].x, neigh[i].y];
                else
                    n = p;
            }

            /*if (x == 4 && y == 6)
            {
                writefln("x=%s, y=%s, p=%s, np[5]=%s, m=%s", x, y, p, np[5], m.r);
            }*/

            // @PixArea
            byte[24] pixarea;
            if (scale == 3 || scale == 4)
            {
                ushort i = cast(ushort) (m.r | (m.g << 8));
                ulong f = forms[i];

                ubyte[4] nareas;
                int na = 0;

                // @H6PMask
                foreach(ubyte a; 0..AREAS)
                {
                    if (f & (1UL << a))
                    {
                        nareas[na] = a;
                        na++;
                    }
                }

                if (na == 2 && nareas[1] >= 48 && nareas[1] < 54)
                   swap(nareas[0], nareas[1]);

                foreach (j, d; nareas[0..na])
                {
                    if (scale == 3)
                    {
                        if (y%2 == 0)
                        {
                            foreach (dn; 0..11)
                            {
                                if (i >= 654 && i < 774 && j == 1)
                                {
                                    pixarea[dn] += pixareas1[AREAS-1][dn] - pixareas1[d][dn];
                                }
                                else
                                {
                                    pixarea[dn] += pixareas1[d][dn];
                                }
                            }
                        }
                        else
                        {
                            foreach (dn; 0..16)
                            {
                                if (i >= 654 && i < 774 && j == 1)
                                {
                                    pixarea[dn] += pixareas2[AREAS-1][dn] - pixareas2[d][dn];
                                }
                                else
                                {
                                    pixarea[dn] += pixareas2[d][dn];
                                }
                            }
                        }
                    }
                    else if (scale == 4)
                    {
                        if (y%2 == 0)
                        {
                            foreach (dn; 0..24)
                            {
                                if (i >= 654 && i < 774 && j == 1)
                                {
                                    pixarea[dn] += pixareas3[AREAS-1][dn] - pixareas3[d][dn];
                                }
                                else
                                {
                                    pixarea[dn] += pixareas3[d][dn];
                                }
                            }
                        }
                        else
                        {
                            foreach (dn; 0..20)
                            {
                                if (i >= 654 && i < 774 && j == 1)
                                {
                                    pixarea[dn] += pixareas4[AREAS-1][dn] - pixareas4[d][dn];
                                }
                                else
                                {
                                    pixarea[dn] += pixareas4[d][dn];
                                }
                            }
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
                            Pixel mp = (m.r == 0 ? p : mix(np, cast(ubyte) m.b));
                            if (m.b & 0x8) swap(ap, mp);

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas1[AREAS-1][dn] - pa);

                            int r, g, b, alpha;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;
                            alpha = pa * mp.a;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;
                            alpha += a * ap.a;

                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 3] += alpha;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 4] += pa+a;
                        }
                    }

                    if (ix+1 < nw && iy-1 > 0)
                    {
                        int dn = 0;

                        Pixel ap = p;
                        Pixel mp = (m.r == 0 ? p : mix(np, cast(ubyte) m.b));
                        if (m.b & 0x8) swap(ap, mp);

                        byte pa = pixarea[dn];
                        byte a = cast(byte) (pixareas1[AREAS-1][dn] - pa);

                        int r, g, b, alpha;
                        r = pa * mp.r;
                        g = pa * mp.g;
                        b = pa * mp.b;
                        alpha = pa * mp.a;

                        r += a * ap.r;
                        g += a * ap.g;
                        b += a * ap.b;
                        alpha += a * ap.a;

                        imgdata16[((iy-1)*nw + ix+1)*5 + 0] += r;
                        imgdata16[((iy-1)*nw + ix+1)*5 + 1] += g;
                        imgdata16[((iy-1)*nw + ix+1)*5 + 2] += b;
                        imgdata16[((iy-1)*nw + ix+1)*5 + 3] += alpha;
                        imgdata16[((iy-1)*nw + ix+1)*5 + 4] += pa+a;
                    }

                    if (ix+1 < nw && iy+3 < nh)
                    {
                        int dn = 10;

                        Pixel ap = p;
                        Pixel mp = (m.r == 0 ? p : mix(np, cast(ubyte) m.b));
                        if (m.b & 0x8) swap(ap, mp);

                        byte pa = pixarea[dn];
                        byte a = cast(byte) (pixareas1[AREAS-1][dn] - pa);

                        int r, g, b, alpha;
                        r = pa * mp.r;
                        g = pa * mp.g;
                        b = pa * mp.b;
                        alpha = pa * mp.a;

                        r += a * ap.r;
                        g += a * ap.g;
                        b += a * ap.b;
                        alpha += a * ap.a;

                        imgdata16[((iy+3)*nw + ix+1)*5 + 0] += r;
                        imgdata16[((iy+3)*nw + ix+1)*5 + 1] += g;
                        imgdata16[((iy+3)*nw + ix+1)*5 + 2] += b;
                        imgdata16[((iy+3)*nw + ix+1)*5 + 3] += alpha;
                        imgdata16[((iy+3)*nw + ix+1)*5 + 4] += pa+a;
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
                            Pixel mp = (m.r == 0 ? p : mix(np, cast(ubyte) m.b));
                            if (m.b & 0x8) swap(ap, mp);

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas2[AREAS-1][dn] - pa);

                            int r, g, b, alpha;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;
                            alpha = pa * mp.a;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;
                            alpha += a * ap.a;

                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 3] += alpha;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 4] += pa+a;
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
                            Pixel mp = (m.r == 0 && m.g == 0 ? p : mix(np, cast(ubyte) m.b));
                            if (m.b & 0x8) swap(ap, mp);

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas3[AREAS-1][dn] - pa);

                            int r, g, b, alpha;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;
                            alpha = pa * mp.a;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;
                            alpha += a * ap.a;

                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 3] += alpha;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 4] += pa+a;
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
                            Pixel mp = (m.r == 0 && m.g == 0 ? p : mix(np, cast(ubyte) m.b));
                            if (m.b & 0x8) swap(ap, mp);

                            byte pa = pixarea[dn];
                            byte a = cast(byte) (pixareas4[AREAS-1][dn] - pa);

                            int r, g, b, alpha;
                            r = pa * mp.r;
                            g = pa * mp.g;
                            b = pa * mp.b;
                            alpha = pa * mp.a;

                            r += a * ap.r;
                            g += a * ap.g;
                            b += a * ap.b;
                            alpha += a * ap.a;

                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 0] += r;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 1] += g;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 2] += b;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 3] += alpha;
                            imgdata16[((iy+dy)*nw + ix+dx)*5 + 4] += pa+a;
                        }
                    }
                }
            }
            else
            {
                // @BigScaleNotes
                ushort i = cast(ushort) (m.r | (m.g << 8));
                ulong f = forms[i];

                ubyte[4] nareas;
                int na = 0;

                // @H6PMask
                foreach(ubyte a; 0..AREAS)
                {
                    if (f & (1UL << a))
                    {
                        nareas[na] = a;
                        na++;
                    }
                }

                if (na == 2 && nareas[1] >= 48 && nareas[1] < 54)
                   swap(nareas[0], nareas[1]);

                /*
                if (x == 239 && y == 125)
                {
                    writefln("%sx%s: na=%s, nareas[]=%s", x, y, na, nareas[0..na]);
                }*/

                foreach (dy; 0..hph)
                {
                    foreach (dx; 0..hpw)
                    {
                        if (hp[dx + dy*hpw] & (1UL << AREAS-1))
                        {
                            Pixel mp = p;

                            bool ec;
                            //static if (false)
                            if (i > 0)
                            {
                                foreach (j, d; nareas[0..na])
                                {
                                    if ( (hp[dx + dy*hpw] & (1UL << d) ? 1 : 0) ^ (i >= 654 && i < 774 && j == 1) )
                                    {
                                        ec = true;
                                        break;
                                    }
                                }
                            }

                            if (m.b & 0x8 ? !ec : ec)
                            {
                                mp = mix(np, cast(ubyte) m.b);
                            }

                            imgdata[((iy+dy)*nw + ix+dx)*4 + 0] = cast(ubyte) mp.r;
                            imgdata[((iy+dy)*nw + ix+dx)*4 + 1] = cast(ubyte) mp.g;
                            imgdata[((iy+dy)*nw + ix+dx)*4 + 2] = cast(ubyte) mp.b;
                            imgdata[((iy+dy)*nw + ix+dx)*4 + 3] = cast(ubyte) mp.a;
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
        foreach (i; 0 .. imgdata16.length/5)
        {
            ushort c = imgdata16[i*5+4];
            if (c > 0)
            {
                imgdata[i*4+0] = cast(ubyte) (imgdata16[i*5+0] / c);
                imgdata[i*4+1] = cast(ubyte) (imgdata16[i*5+1] / c);
                imgdata[i*4+2] = cast(ubyte) (imgdata16[i*5+2] / c);
                imgdata[i*4+3] = cast(ubyte) (imgdata16[i*5+3] / c);
            }
        }
    }

    writefln("Writing image");
    Image myImg = new Img!(Px.R8G8B8A8)(nw, nh, imgdata);
    myImg.write(outpict);
}
