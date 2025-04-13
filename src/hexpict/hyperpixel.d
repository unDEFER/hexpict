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

import std.algorithm;
import std.typecons;
import std.math;
import std.stdio;
import std.conv;
import std.file;
import std.bitmanip;

import hexpict.color;

void neighbours(int x, int y, int[][] neigh)
{
    // @H6PNeighbours
    neigh[5][0] = x - 1;
    neigh[5][1] = y;

    neigh[2][0] = x + 1;
    neigh[2][1] = y;

    neigh[0][1] = neigh[1][1] = y - 1;

    neigh[4][1] = neigh[3][1] = y + 1;

    if (y%2 == 0)
    {
        neigh[4][0] = neigh[0][0] = x - 1;

        neigh[3][0] = neigh[1][0] = x;
    }
    else
    {
        neigh[0][0] = neigh[4][0] = x;
        neigh[1][0] = neigh[3][0] = x + 1;
    }
}

struct Point
{
    float x, y;
}

// @PointsOfHexagon
Point[61] points;
int pw = 0;

/*
 * Generates mask of ingoing in areas of hyperpixel
 * of point (x, y) if width of hyperpixel is w
 * and height is h.
 * @HyperPixel @HyperMask
 */
void hypermask61(bool[] hpdata, int w, int h, ubyte[] form)
{
    struct YInter
    {
        int x1, x2;
        byte ydir;
        float xc, yc;
    }

    float area = 0.0f;
    foreach(i, f1; form)
    {
        ubyte f2 = form[(i+1)%$];

        Point p1 = points[f1];
        Point p2 = points[f2];

        area += p1.x*p2.y - p2.x*p1.y;
    }

    if (area == 0) return;

    int debugy = -1;

    if (debugy >= 0)
    {
        foreach(f; form)
        {
            writefln("%s", points[f]);
        }
    }

    foreach(y; 0..h)
    {
        float fy = y + 0.5f;
        YInter[] yinters;

        int continued;
        foreach(i, f1; form)
        {
            ubyte f2 = form[(i+1)%$];

            Point p1 = points[f1];
            Point p2 = points[f2];

            if (fy >= p1.y && fy <= p2.y || fy >= p2.y && fy <= p1.y)
            {
                if (f1 < 24 && f2 < 24)
                {
                    ubyte f41 = cast(ubyte) (f1 - f1%4);
                    ubyte f42 = cast(ubyte) (f2 - f2%4);

                    if (f41 == f42 || (f41+4)%24 == f42 || (f42+4)%24 == f41 )
                    {
                        continued++;
                        continue;
                    }
                }

                int x1, x2;

                if (p1.x < p2.x)
                {
                    x1 = cast(int) round(p1.x);
                    x2 = cast(int) round(p2.x);
                }
                else
                {
                    x1 = cast(int) round(p2.x);
                    x2 = cast(int) round(p1.x);
                }
                
                if (x1 >= w) x1 = w-1;
                if (x2 >= w) x2 = w-1;

                float xc = p1.x;
                float yc = (p1.y + p2.y)/2.0f;

                if (abs(p1.y - p2.y) > 0.01)
                {
                    float ux1 = p1.x;
                    float uy1 = p1.y;
                    float ux2 = p2.x;
                    float uy2 = p2.y;

                    float dx = ux2 - ux1;
                    float dy = uy2 - uy1;

                    float yy0 = y + 0.0f;
                    float yy1 = y + 1.0f;

                    float xx0 = (yy0 - uy1)*dx/dy + ux1;
                    xc = (fy - uy1)*dx/dy + ux1;
                    float xx1 = (yy1 - uy1)*dx/dy + ux1;

                    if (y == debugy)
                    {
                        writefln("xx0 = %s, xx1 = %s, p1.y = %s, p2.y = %s", xx0, xx1, p1.y, p2.y);
                    }

                    float minx, maxx;
                    if (xx0 < xx1)
                    {
                        minx = xx0;
                        maxx = xx1;
                    }
                    else
                    {
                        minx = xx1;
                        maxx = xx0;
                    }

                    int cx0 = cast(int) floor(minx);
                    int cx1 = cast(int) ceil(maxx);
                    int ix0, ix1;

                    if (cx0 < 0) cx0 = 0;
                    if (cx1 > w) cx1 = w;

                    if (y == debugy)
                    {
                        writefln("cx0 = %s, cx1 = %s", cx0, cx1);
                    }

                    if (p2.y < p1.y)
                    {
                        ix0 = cx0-1;
                        ix1 = cx0-1;

                        foreach (x; cx0..cx1)
                        {
                            float fx0 = x + 0.0f;
                            float fx1 = x + 1.0f;

                            float fy0 = (fx0 - xx0)/(xx1-xx0) + yy0;
                            float fy1 = (fx1 - xx0)/(xx1-xx0) + yy0;

                            if (y == debugy)
                            {
                                writefln(">> x = %s, fy0 = %s, fy1 = %s (<0.5 %s != %s)", x, fy0, fy1, (fy0+fy1)/2.0f < (yy0+yy1)/2.0f, p2.x > p1.x);
                            }

                            if (ix0 < cx0 && (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x)))
                                ix0 = x;

                            if (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x))
                                ix1 = x;
                        }

                        if (ix0 < cx0) ix0 = cx0;
                        if (ix1 < cx0) ix1 = cx1;

                        if (y == debugy)
                        {
                            writefln(">> x = %s-%s, ix = %s-%s", x1, x2, ix0, ix1);
                        }
                    }
                    else
                    {
                        ix0 = cx1;
                        ix1 = cx1;

                        foreach (x; cx0..cx1)
                        {
                            float fx0 = x + 0.0f;
                            float fx1 = x + 1.0f;

                            float fy0 = (fx0 - xx0)/(xx1-xx0) + yy0;
                            float fy1 = (fx1 - xx0)/(xx1-xx0) + yy0;

                            if (y == debugy)
                            {
                                writefln("<< x = %s, fy0 = %s, fy1 = %s (<0.5 %s != %s)", x, fy0, fy1, (fy0+fy1)/2.0f < (yy0+yy1)/2.0f, p2.x > p1.x);
                            }

                            if (ix0 >= cx1 && (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x)))
                                ix0 = x;

                            if (((fy0+fy1)/2.0f < (yy0+yy1)/2.0f) != (p2.x > p1.x))
                                ix1 = x;
                        }

                        if (ix0 >= cx1) ix0 = cx0;
                        if (ix1 >= cx1) ix1 = cx1;

                        if (y == debugy)
                        {
                            writefln("<< x = %s-%s, ix = %s-%s", x1, x2, ix0, ix1);
                        }
                    }

                    if (ix0 > x1)
                    {
                        if (ix0 < x2)
                            x1 = ix0;
                        else
                            x1 = x2;
                    }
                    if (ix1 < x2)
                    {
                        if (ix1 > x1)
                            x2 = ix1;
                        else
                            x2 = x1;
                    }
                }

                if (abs(p1.y - fy) <= 0.1)
                    xc = p2.x;
                if (abs(p2.y - fy) <= 0.1)
                    xc = p1.x;

                yinters ~= YInter(x1, x2, cast(byte) (p2.y - p1.y), xc, yc);
            }
        }

        alias myComp = (x, y) => (x.xc < y.xc || x.xc == y.xc && x.yc > y.yc);

        yinters = yinters.sort!(myComp).release();

        int xp = 0;
        byte ydirp;
        foreach(yinter; yinters)
        {
            int sx = (yinter.ydir >= 0) ? yinter.x1 : xp;

            if (y == debugy)
            {
                writefln("yinter = %s, sx = %s", yinter, sx);
            }

            foreach (x; sx .. yinter.x2+1)
            {
                hpdata[y*w + x] = true;
            }

            xp = yinter.x2+1;
            ydirp = yinter.ydir;
        }

        if (y == debugy)
        {
            writefln("ydirp = %s, yinters.length = %s, area = %s, continued = %s",
                    ydirp, yinters, area, continued);
        }

        if (ydirp > 0 || yinters.length == 0 && ((area > 0) != (continued > 0 && continued%2 == 0)))
        {
            foreach (x; xp .. w)
            {
                hpdata[y*w + x] = true;
            }
        }
    }
}

Tuple!(ubyte[], "form", ubyte, "rot") normalize_form(ubyte[] form)
{
    if (form.length < 2) return tuple!("form", "rot")(form, cast(ubyte) 0);

    ubyte[] wr_form;
    foreach (dir; form)
    {
        ubyte off, r;
        if (dir < 24)
        {
            off = 0;
            r = 4;
        }
        else if (dir < 42)
        {
            off = 24;
            r = 3;
        }
        else if (dir < 54)
        {
            off = 42;
            r = 2;
        }
        else if (dir < 60)
        {
            off = 54;
            r = 1;
        }
        else
        {
            off = 60;
            r = 0;
        }

        if (r > 0)
            dir = cast(ubyte) (off + (dir-off)%r);
        wr_form ~= dir;
    }

    ptrdiff_t mindf = minIndex(wr_form);
    ubyte minv = wr_form[mindf];
    ubyte[] minds = [cast(ubyte) mindf];
    ubyte[] minds2;

    foreach (i, dir; wr_form[mindf+1..$])
    {
        if (dir == minv)
        {
            minds ~= cast(ubyte)(mindf+1+i);
        }
    }

    if (minds.length > 1)
    {
        ubyte till = cast(ubyte) ((wr_form.length + minds.length-1) / minds.length);
        //writefln("form %s, wr_form %s, minds %s", form, wr_form, minds);

        foreach (off; 1..till)
        {
            ubyte[] nexts;
            foreach (mind; minds)
            {
                nexts ~= wr_form[(mind+off)%$];
            }

            mindf = minIndex(nexts);
            minv = nexts[mindf];
            minds2 ~= minds[mindf];

            foreach (i, dir; nexts[mindf+1..$])
            {
                if (dir == minv)
                {
                    minds2 ~= minds[mindf+1+i];
                }
            }

            swap(minds, minds2);
            minds2.length = 0;

            //writefln("off %s, minds %s", off, minds);

            if (minds.length == 1)
            {
                break;
            }
        }
    }

    form = form[minds[0]..$] ~ form[0..minds[0]];
    ubyte rot = get_rot(form[0]);

    foreach(ref dir; form)
    {
        auto o = get_off_r(dir);
        if (o.r == 0) continue;

        dir = cast(ubyte) (o.off + (dir-o.off + (6-rot)*o.r)%(6*o.r));
    }

    //writefln("return %s", tuple!("form", "rot")(form, rot));
    return tuple!("form", "rot")(form, rot);
}

Tuple!(ubyte, "off", ubyte, "r") get_off_r(ubyte dir)
{
    if (dir < 24)
    {
        return tuple!("off", "r")(cast(ubyte) 0, cast(ubyte) 4);
    }
    else if (dir < 42)
    {
        return tuple!("off", "r")(cast(ubyte) 24, cast(ubyte) 3);
    }
    else if (dir < 54)
    {
        return tuple!("off", "r")(cast(ubyte) 42, cast(ubyte) 2);
    }
    else if (dir < 60)
    {
        return tuple!("off", "r")(cast(ubyte) 54, cast(ubyte) 1);
    }
    else return tuple!("off", "r")(cast(ubyte) 60, cast(ubyte) 0);
}

ubyte get_rot(ubyte dir)
{
    auto o = get_off_r(dir);

    return cast(ubyte) ((dir-o.off)/o.r);
}

/*
 * Generates hyperpixel with width w.
 * Returns false if wasn't generated.
 * @HyperPixel
 */
BitArray *hyperpixel(int w, ubyte[12] form12, ubyte rotate, bool _debug = false)
{
    ubyte[] form;
    foreach (f; form12)
    {
        if (f == 0) break;
        f--;

        if (rotate > 0)
        {
            if (f < 24)
            {
                f = (f + 4*rotate)%24;
            }
            else if (f < 42)
            {
                f = 24 + (f-24 + 3*rotate)%18;
            }
            else if (f < 54)
            {
                f = 42 + (f-42 + 2*rotate)%12;
            }
            else if (f < 60)
            {
                f = 54 + (f-54 + rotate)%6;
            }
        }

        form ~= f;
    }

    if (form.length > 1 && form[0] < 24 && form[$-1] < 24)
    {
        ubyte f = form[$-1];
        ubyte f4 = f%4;
        f -= f4;

        ubyte fe = form[0];
        fe -= fe%4;

        if (f != fe || form[$-1] < form[0])
        {
            if (f4 > 0)
            {
                form ~= f;
            }

            do
            {
                f = (f+20)%24;
                if (f == form[0]) break;
                form ~= f;
            }
            while (f != fe);
        }
    }

    if (form.length > 1 && form[0] == form[$-1])
        form = form[0..$-1];

    //writefln("form=%s", form);

    int h = cast(int) round(w * 2.0 / sqrt(3.0));
    int hh = cast(int) ceil(h/4.0);
    int w5 = cast(int) round(0.5*w);

    /*        0
     *    23  oo 1
     *  22  oooooo 2
     *21  oooooooooo 3
     *20oooooooooooooo 4
     *19oooooooooooooo 5
     *18oooooooooooooo 6
     *17oooooooooooooo 7
     *16  oooooooooo  8
     *1514  oooooo 10 9
     *    13  oo 11
     *        12
     */

    // @PointsOfHexagon
    if (pw != w)
    {
        pw = w;

        points[0] = Point(w/2.0f, 0);
        points[4] = Point(w, h/4.0f);
        points[8] = Point(w, h - h/4.0f);
        points[12] = Point(w/2.0f, h);
        points[16] = Point(0, h - h/4.0f);
        points[20] = Point(0, h/4.0f);

        points[60] = Point(w/2.0f, h/2.0f);

        foreach(p; 0..6)
        {
            int p0 = p*4;

            foreach(i; 1..4)
            {
                int p1 = (27 - i*3)*i + p*(4-i);

                float xx = (points[p0].x*(4-i) + points[60].x*i)/4.0f;
                float yy = (points[p0].y*(4-i) + points[60].y*i)/4.0f;

                points[p1] = Point(xx, yy);
            }
        }
        
        foreach(z; 0..3)
        {
            int v = 4 - z;
            foreach(p; 0..6)
            {
                int o = (27 - z*3)*z;
                int p0 = o + p*v;
                int p1 = o + ((p+1)*v) % (6*v);

                foreach(i; 1..v)
                {
                    float xx = (points[p0].x*(v-i) + points[p1].x*i)/v;
                    float yy = (points[p0].y*(v-i) + points[p1].y*i)/v;

                    points[p0+i] = Point(xx, yy);
                }
            }
        }
    }

    // @HyperPixelSuccess
    bool success = (w5 == (w-w5));
    foreach (i; 1..hh)
    {
        int ww = cast(int) round(0.5*w*i/hh);
        int ww2 = cast(int) round(0.5*w*(hh-i)/hh);

        success &= (ww == (w5-ww2));
    }

    if (success)
    {
        //writefln("Generate hyperpixel 24 %sx%s (%s, %s)", w, h, 1.0*w/h, 1.0*(h-hh)/w);

        // @HyperMask
        bool[] hpdata = new bool[w*h];
        foreach (i; hh..(h-hh+2))
        {
            foreach(j; 0..w)
            {
                hpdata[(i-1)*w + j] = true;
            }
        }

        foreach (i; 1..hh)
        {
            int ww = cast(int) round(0.5*w*i/hh);

            foreach(j; 0..w5)
            {
                if (w5-j <= ww)
                {
                    hpdata[(i-1)*w + j] = true;
                    hpdata[(h-i)*w + j] = true;
                }
            }

            foreach(j; 0..(w-w5))
            {
                if (j+1 <= ww)
                {
                    hpdata[(i-1)*w + w5+j] = true;
                    hpdata[(h-i)*w + w5+j] = true;
                }
            }
        }

        if (form.length > 0)
        {
            bool[] hpdata2 = new bool[w*h];
            hypermask61(hpdata2, w, h, form);

            foreach (y; 0..h)
            {
                foreach (x; 0..w)
                {
                    hpdata[y*w + x] &= hpdata2[y*w + x];
                }
            }
        }

        if (_debug)
        {
            foreach (y; 0..h)
            {
                writef("%2d ", y);
                foreach (x; 0..w)
                {
                    write(hpdata[y*w + x] ? '+' : '.');
                }
                writeln();
            }
        }

        return new BitArray(hpdata);
    }

    return null;
}

void scalelist()
{
    // @HyperPixel @HyperPixelSuccess
    writefln("Available hyperpixel sizes:");
    write("4");
    foreach (w; 5..100)
    {
        int h = cast(int) round(w * 2.0 / sqrt(3.0));
        int hh = cast(int) ceil(h/4.0);
        int w5 = cast(int) round(0.5*w);

        bool success = (w5 == (w-w5));
        foreach (i; 1..hh)
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

/+
// @PointsOfHexagon
private FPoint[25] points;

private
{
    immutable float fw = 1.0f;
    immutable float fh = fw * 2.0f / sqrt(3.0f);
    immutable float fvh = fh/4.0f;
}

static this()
{
    /*        0
     *    23  oo 1
     *  22  oooooo 2
     *21  oooooooooo 3
     *20oooooooooooooo 4
     *19oooooooooooooo 5
     *18oooooooooooooo 6
     *17oooooooooooooo 7
     *16  oooooooooo  8
     *1514  oooooo 10 9
     *    13  oo 11
     *        12
     */

    points[0] = FPoint(fw/2, 0);
    points[4] = FPoint(fw, fh/4);
    points[8] = FPoint(fw, fh - fh/4);
    points[12] = FPoint(fw/2, fh);
    points[16] = FPoint(0, fh - fh/4);
    points[20] = FPoint(0, fh/4);

    foreach(p; 0..6)
    {
        int p0 = p*4;
        int p1 = ((p+1)*4) % 24;

        foreach(i; 1..4)
        {
            float xx = (points[p0].x*(4-i) + points[p1].x*i)/4.0f;
            float yy = (points[p0].y*(4-i) + points[p1].y*i)/4.0f;

            points[i+p*4] = FPoint(xx, yy);
        }
    }
    
    points[24] = FPoint(fw/2, fh/2);
}

struct Vertex
{
    uint x, y;
    byte p;
}

void to_float_coords(Vertex v, out float fx, out float fy)
{
    fx = (v.x + (v.y%2 == 1 ? 0.5f : 0.0f))*fw + points[v.p].x;
    fy = v.y*(fh-fvh) + points[v.p].y;
}
+/

