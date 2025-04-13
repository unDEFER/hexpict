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
import std.bitmanip;
import bindbc.sdl;

import hexpict.h6p;
import hexpict.color;
import hexpict.colors;
import hexpict.hyperpixel;

struct PaletteTree
{
    byte ch = -1;
    float mid;
    PaletteTree *left;
    PaletteTree *right;

    ushort color;
}

ushort find_color_in_palette(PaletteTree *ptree, Color color)
{
    if (ptree.ch == -1) return ptree.color;
    return find_color_in_palette(color.channels[ptree.ch] < ptree.mid ? ptree.left : ptree.right, color);
}

ushort find_color_in_palette(Color[] cpalette, Color color)
{
    ushort icol;
    float mindiff = 1e10f;
    foreach (i, pcol; cpalette)
    {
        float dist = color_dist(&color, &pcol, ErrCorrection.ORDINARY);
        if (dist < mindiff)
        {
            icol = cast(ushort) i;
            mindiff = dist;
        }
    }

    return icol;
}

/*
 * Convert `inpict` pixel-file into `outpict` h6p image
 * with `scale` scaledown
 * @Pixel2Hex
 */
H6P *pixel2hex(SDL_Surface *image, int scale, string space_name)
{
    // @Pixel2HexScaleUp
    int scaleup = 1;

    if (scale == 4 || scale == 2 || scale == 1)
    {
        scaleup = 8/scale;
        scale = 8;
    }       

    int iw = image.w;
    int ih = image.h;

    // @HyperPixelAnatomy
    int hpw = scale;
    float hpwf = hpw;
    float hphf = round(hpwf * 2.0 / sqrt(3.0));
    int hph = cast(int)hphf;

    ubyte[12] form12;
    BitArray *hp = hyperpixel(hpw, form12, 0);

    float hhf = floor(hphf/4.0);
    uint hh = cast(uint) hhf;

    int nw = iw*scaleup/hpw;
    int nh = ih*scaleup/(hph-hh);

    ColorSpace *space = new ColorSpace;
    assert(space !is null);
    *space = cast(ColorSpace) SRGB_SPACE;

    switch(space_name)
    {
        case "RGB":
            space.type = ColorType.RGB;
            space.companding = CompandingType.GAMMA_2_2;
            space.alpha_companding = CompandingType.NONE;
            break;

        case "RMB":
            space.type = ColorType.RMB;
            space.companding = CompandingType.HLG;
            space.alpha_companding = CompandingType.NONE;

            float rm = 1.0029;
            space.bounds = new double[][3];
            for (size_t i = 0; i < 3; i++)
            {
                space.bounds[i] = new double[2];
            }
            space.bounds[0][0] = 0.0;
            space.bounds[0][1] = 0.0;
            space.bounds[0][2] = 0.0;
            space.bounds[1][0] = rm;
            space.bounds[1][1] = rm;
            space.bounds[1][2] = rm;
            break;

        case "LMS":
            space.type = ColorType.LMS;
            space.companding = CompandingType.GAMMA_2_2;
            space.alpha_companding = CompandingType.NONE;
            break;

        case "ITP":
            space.type = ColorType.ITP;
            space.companding = CompandingType.NONE;
            space.alpha_companding = CompandingType.NONE;

            space.bounds = new double[][3];
            for (size_t i = 0; i < 3; i++)
            {
                space.bounds[i] = new double[2];
            }
            itp_bounds_by_color_space(space, space.bounds);
            break;

        default:
            assert(false, "Unsupported color space");
    }
    
    calc_rgb_matrices(space);

    ColorSpace *rgbspace = get_rgbspace(space);

    H6P* h6p_image = h6p_create(space, nw, nh);

    Color[] colors;
    foreach(y; 0..ih)
    {
        foreach(x; 0..iw)
        {
            uint pixel_value;
            ubyte *pixel = cast(ubyte*) (image.pixels + y * image.pitch + x * image.format.BytesPerPixel);
            switch(image.format.BytesPerPixel) {
                case 1:
                    pixel_value = *cast(ubyte *)pixel;
                    break;
                case 2:
                    pixel_value = *cast(ushort *)pixel;
                    break;
                case 3:
                    pixel_value = *cast(uint *)pixel & (~image.format.Amask);
                    break;
                case 4:
                    pixel_value = *cast(uint *)pixel;
                    break;
                default:
                    assert(0);
            }
            ubyte r, g, b, a;
            SDL_GetRGBA(pixel_value,image.format,&r,&g,&b,&a);
            ubyte[4] p = [r, g, b, a];
            /*if (x == DBGX && y == DBGY)
              {
              printf("{dx}x{dy} -- {}x{}: {:?}", x0/scaleup, y0/scaleup, p);
              }*/
            Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
            color_from_u8(p, rgbspace, &pr);
            color_convert(&pr, &ITP_SPACE, ErrCorrection.ORDINARY);

            colors ~= pr;
        }
    }

    int palette_size = 1024;
    Color[][] buckets = [colors];
    Color[][] buckets2;
    float[2][4] ranges;

    Color[] cpalette;

    PaletteTree *ptree = new PaletteTree;
    PaletteTree *[] buckets_ptree = [ptree];
    PaletteTree *[] buckets_ptree2;

    float xrange = 1.0f;
    uint bucketssize = 1;
    while (xrange >= 0.0f && cpalette.length < palette_size)
    {
        float mrange = 0.0f;
        foreach (bi, bucket; buckets)
        {
            foreach (ref range; ranges)
            {
                range[0] = 1e10;
                range[1] = -1e10;
            }

            foreach (color; bucket)
            {
                foreach(i, channel; color.channels)
                {
                    if (channel < ranges[i][0])
                    {
                        ranges[i][0] = channel;
                    }

                    if (channel > ranges[i][1])
                    {
                        ranges[i][1] = channel;
                    }
                }
            }

            //writefln("bi %s ranges %s, %s colors (bucketssize=%s)", bi, ranges, bucket.length, bucketssize);

            int r = 0;
            float maxrange = 0.0f;

            foreach (i, range; ranges)
            {
                if (range[1] - range[0] > maxrange)
                {
                    maxrange = range[1] - range[0];
                    r = cast(int) i;
                }
            }

            if (maxrange > mrange) mrange = maxrange;

            if (xrange > 0.0f && buckets.length < palette_size)
            {
                if (maxrange == 0.0f || bucket.length == 1 || bucketssize >= palette_size)
                {
                    buckets2 ~= bucket;
                    buckets_ptree2 ~= buckets_ptree[bi];
                }
                else
                {
                    float midr = (ranges[r][0] + ranges[r][1])/2.0f;
                    //writefln("r=%s, midr=%s", r, midr);

                    Color[][2] twobuckets;
                    foreach (color; bucket)
                    {
                        twobuckets[color.channels[r] < midr ? 0 : 1] ~= color;
                    }

                    if (twobuckets[0].length > 0 && twobuckets[1].length > 0)
                    {
                        buckets2 ~= twobuckets;
                        buckets_ptree[bi].ch = cast(byte) r;
                        buckets_ptree[bi].mid = midr;
                        buckets_ptree[bi].left = new PaletteTree;
                        buckets_ptree[bi].right = new PaletteTree;
                        buckets_ptree2 ~= [buckets_ptree[bi].left, buckets_ptree[bi].right];
                        bucketssize++;
                    }
                    else
                    {
                        buckets2 ~= bucket;
                        buckets_ptree2 ~= buckets_ptree[bi];
                    }
                }
            }
            else
            {
                alias myComp = (x, y) => x.channels[r] < y.channels[r];
                bucket.sort!(myComp);
                buckets_ptree[bi].color = cast(ushort) cpalette.length;
                cpalette ~= bucket[$/2];
            }
        }

        swap(buckets, buckets2);
        swap(buckets_ptree, buckets_ptree2);
        buckets2.length = 0;
        buckets_ptree2.length = 0;
        if (xrange == 0.0f) xrange = -1.0f;
        else xrange = mrange;

        assert(bucketssize == buckets.length || buckets.length == 0);
    }
    writefln("Palette size %s", cpalette.length);

    ubyte[] palette;
    foreach (icol, color; cpalette)
    {
        color_convert(&color, h6p_image.space, ErrCorrection.ORDINARY);
        foreach(ch; color.channels)
        {
            ushort ch16 = cast(ushort) round(min(ch * 65535.0f, 65535.0f));
            ubyte[2] be16_ch = nativeToBigEndian(ch16);
            palette ~= be16_ch;
        }
    }

    /*foreach (ref color; cpalette)
    {
        color_convert(&color, rgbspace, ErrCorrection.ORDINARY);
    }*/

    h6p_image.cpalette[0] = cpalette;
    h6p_image.palette[0] = palette;

    // @Pixel2HexGrayImage
    ubyte[] indexed = new ubyte[hpw * hph];
    assert(indexed !is null);

    int ok, fails;
    bool _debug;

    // @Pixel2HexFormRecognition
    for (int y = 0; y < nh; y++)
    {
        writef("\r(pixel2hex) %d / %d", y, nh);
        stdout.flush();
        int iy = y*(hph-hh);

        for (int x = 0; x < nw; x++)
        {
            _debug = (x==298 && y==60);
            Pixel *h6p_pixel = h6p_image.pixel(x, y);

            int ix;

            if (y%2 == 0)
            {
                ix = x*hpw;
            }
            else
            {
                ix = hpw/2 + x*hpw;
            }

            Color pc1, pc2;
            ubyte bestf;
            float mostdiff = -1.0;

            ubyte gmin = 255;
            ubyte gmax = 0;

            uint gsum = 0;
            uint gcount = 0;

            colors.length = 0;

            for (int dy = 0; dy < hph; dy++)
            {
                for (int dx = 0; dx < hpw; dx++)
                {
                    // @HyperMask
                    if ((*hp)[dx + dy*hpw])
                    {
                        int x0 = ix + dx;
                        int y0 = iy + dy;

                        // @Pixel2HexScaleUp
                        if (x0/scaleup < iw && y0/scaleup < ih)
                        {
                            uint pixel_value;
                            ubyte *pixel = cast(ubyte*) (image.pixels + (y0/scaleup) * image.pitch + (x0/scaleup) * image.format.BytesPerPixel);
                            switch(image.format.BytesPerPixel) {
                                case 1:
                                    pixel_value = *cast(ubyte *)pixel;
                                    break;
                                case 2:
                                    pixel_value = *cast(ushort *)pixel;
                                    break;
                                case 3:
                                    pixel_value = *cast(uint *)pixel & (~image.format.Amask);
                                    break;
                                case 4:
                                    pixel_value = *cast(uint *)pixel;
                                    break;
                                default:
                                    assert(0);
                            }
                            ubyte r, g, b, a;
                            SDL_GetRGBA(pixel_value,image.format,&r,&g,&b,&a);
                            ubyte[4] p = [r, g, b, a];
                            /*if (x == DBGX && y == DBGY)
                              {
                              printf("{dx}x{dy} -- {}x{}: {:?}", x0/scaleup, y0/scaleup, p);
                              }*/
                            Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                            color_from_u8(p, rgbspace, &pr);
                            color_convert(&pr, &ITP_SPACE, ErrCorrection.ORDINARY);

                            colors ~= pr;
                        }
                    }
                }
            }

            buckets = [colors];
            buckets2 = [];

            Color[] hexpalette;

            bucketssize = 1;

            float MaxRange;
            do
            {
                MaxRange = 0.0f;
                foreach (bi, bucket; buckets)
                {
                    foreach (ref range; ranges)
                    {
                        range[0] = 1e10;
                        range[1] = -1e10;
                    }

                    foreach (color; bucket)
                    {
                        foreach(i, channel; color.channels)
                        {
                            if (channel < ranges[i][0])
                            {
                                ranges[i][0] = channel;
                            }

                            if (channel > ranges[i][1])
                            {
                                ranges[i][1] = channel;
                            }
                        }
                    }

                    //writefln("ranges %s", ranges);

                    int r = 0;
                    float maxrange = 0.0f;

                    foreach (i, range; ranges)
                    {
                        if (range[1] - range[0] > maxrange)
                        {
                            maxrange = range[1] - range[0];
                            r = cast(int) i;
                        }
                    }

                    if (maxrange > MaxRange)
                    {
                        MaxRange = maxrange;
                    }

                    if (720.0f * maxrange > 10.0f && bucketssize < 4)
                    {
                        float midr = (ranges[r][0] + ranges[r][1])/2.0f;

                        Color[][2] twobuckets;
                        foreach (color; bucket)
                        {
                            twobuckets[color.channels[r] < midr ? 0 : 1] ~= color;
                        }

                        if (twobuckets[0].length > 0 && twobuckets[1].length > 0)
                        {
                            buckets2 ~= twobuckets;
                            bucketssize++;
                        }
                        else
                        {
                            buckets2 ~= bucket;
                        }
                    }
                    else
                    {
                        alias myComp = (x, y) => x.channels[r] < y.channels[r];
                        bucket.sort!(myComp);
                        hexpalette ~= bucket[$/2];
                    }
                }

                swap(buckets, buckets2);
                buckets2.length = 0;
            }
            while (720.0f * MaxRange > 10.0f && hexpalette.length < 4);

            /*foreach (ref color; hexpalette)
            {
                color_convert(&color, rgbspace, ErrCorrection.ORDINARY);
            }*/

            if (hexpalette.length > 1)
            {
                if (_debug)
                    writefln("hexpalette.length = %s", hexpalette.length);

                struct Area
                {
                    int left = int.max;
                    int right = int.min;
                    int top = int.max;
                    int bottom = int.min;

                    int lefty0, lefty1;
                    int righty0, righty1;
                    int topx0, topx1;
                    int bottomx0, bottomx1;

                    void extend(int x, int y)
                    {
                        if (x < left)
                        {
                            left = x;
                            lefty0 = y;
                            lefty1 = y;
                        }
                        else if (x == left)
                        {
                            if (y < lefty0) lefty0 = y;
                            if (y > lefty1) lefty1 = y;
                        }

                        if (x > right)
                        {
                            right = x;
                            righty0 = y;
                            righty1 = y;
                        }
                        else if (x == right)
                        {
                            if (y < righty0) righty0 = y;
                            if (y > righty1) righty1 = y;
                        }


                        if (y < top)
                        {
                            top = y;
                            topx0 = x;
                            topx1 = x;
                        }
                        else if (y == top)
                        {
                            if (x < topx0) topx0 = x;
                            if (x > topx1) topx1 = x;
                        }

                        if (y > bottom)
                        {
                            bottom = y;
                            bottomx0 = x;
                            bottomx1 = x;
                        }
                        else if (y == bottom)
                        {
                            if (x < bottomx0) bottomx0 = x;
                            if (x > bottomx1) bottomx1 = x;
                        }
                    }

                    int calc_area()
                    {
                        return (right - left + 1) * (bottom - top + 1);
                    }
                }

                int[] icount = new int[hexpalette.length];
                Area[] iarea = new Area[hexpalette.length];

                int count;
                // @Pixel2HexAverage
                for (int dy = 0; dy < hph; dy++)
                {
                    for (int dx = 0; dx < hpw; dx++)
                    {
                        // @HyperMask
                        if ((*hp)[dx + dy*hpw])
                        {
                            int x0 = ix + dx;
                            int y0 = iy + dy;

                            // @Pixel2HexScaleUp
                            if (x0/scaleup < iw && y0/scaleup < ih)
                            {
                                uint pixel_value;
                                ubyte *pixel = cast(ubyte*) (image.pixels + (y0/scaleup) * image.pitch + (x0/scaleup) * image.format.BytesPerPixel);
                                switch(image.format.BytesPerPixel) {
                                    case 1:
                                        pixel_value = *cast(ubyte *)pixel;
                                        break;
                                    case 2:
                                        pixel_value = *cast(ushort *)pixel;
                                        break;
                                    case 3:
                                        pixel_value = *cast(uint *)pixel & (~image.format.Amask);
                                        break;
                                    case 4:
                                        pixel_value = *cast(uint *)pixel;
                                        break;
                                    default:
                                        assert(0);
                                }
                                ubyte r, g, b, a;
                                SDL_GetRGBA(pixel_value,image.format,&r,&g,&b,&a);
                                ubyte[4] p = [r, g, b, a];
                                /*if (x == DBGX && y == DBGY)
                                  {
                                  printf("{dx}x{dy} -- {}x{}: {:?}", x0/scaleup, y0/scaleup, p);
                                  }*/
                                Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                                color_from_u8(p, rgbspace, &pr);
                                color_convert(&pr, &ITP_SPACE, ErrCorrection.ORDINARY);

                                uint index = find_color_in_palette(hexpalette, pr);
                                indexed[dx + dy*hpw] = cast(ubyte) index;
                                icount[index]++;
                                iarea[index].extend(dx, dy);
                                count++;
                            }
                        }
                    }
                }
                
                //writefln("icount=%s, count=%s", icount, count);

                int[] sarea;

                foreach (a; iarea)
                {
                    sarea ~= a.calc_area();
                }

                ubyte base = cast(ubyte) sarea.maxIndex;
                h6p_pixel.color = find_color_in_palette(ptree, hexpalette[base]);
                if (_debug)
                    writefln("Base color: %s", hexpalette[base]);

                bool is_ok = true;
iarea:
                foreach (index, area; iarea)
                {
                    if (index == base) continue;

                    ushort extra_color = find_color_in_palette(ptree, hexpalette[index]);
                    if (_debug)
                        writefln("Extra color: %s", hexpalette[index]);

                    if (_debug)
                        writefln("INDEX %s of %s", index, iarea.length);
                    static ushort[ubyte[12]] FORMS;

                    ubyte[12] get_form(ref Area area, ubyte[] indexed, ubyte index, out ubyte rot, out int err, out int suc)
                    {
                        bool if_connect(int x0, int x1, int y0, int y1, bool left, bool up)
                        {
                            int total, ones;

                            for (int dy = y0; dy <= y1; dy++)
                            {
                                for (int dx = x0; dx <= x1; dx++)
                                {
                                    // @HyperMask
                                    if ((*hp)[dx + dy*hpw])
                                    {
                                        int ddx = (left ? dx - x0 : x1 - dx) + 1;
                                        int ddy = (up ? dy - y0 : y1 - dy) + 1;
                                        int dw = x1-x0+1;
                                        int dh = y1-y0+1;

                                        if (1.0f*ddy/ddx > 1.0f*dh/dw)
                                        {
                                            if (indexed[dx + dy*hpw] == index)
                                            {
                                                ones++;
                                            }

                                            //writefln("%sx%s: %sx%s %s", dx, dy, ddx, ddy, (gray[dx + dy*hpw] >= gavg) != !ggreater);
                                            total++;
                                        }
                                    }
                                }
                            }

                            if (_debug)
                                writefln("x:%s-%s, y:%s-%s, ones=%s, total=%s", x0, x1, y0, y1, ones, total);
                            return ones < total/2;
                        }

                        /*
                        bool lt = if_connect(area.left, area.topx0, area.top, area.lefty0, true, false);
                        bool rt = if_connect(area.topx1, area.right, area.top, area.righty0, false, false);
                        bool lb = if_connect(area.left, area.bottomx0, area.lefty1, area.bottom, true, true);
                        bool rb = if_connect(area.bottomx1, area.right, area.righty1, area.bottom, false, true);
                        */

                        Point[] points;
                        points ~= Point(hpwf/2.0f, 0);
                        points ~= Point(hpwf, hphf/4.0f);
                        points ~= Point(hpwf, hphf - hphf/4.0f);
                        points ~= Point(hpwf/2.0f, hphf);
                        points ~= Point(0, hphf - hphf/4.0f);
                        points ~= Point(0, hphf/4.0f);

                        if (_debug)
                            writefln("Start points: %s", points);

                        if (area.left <= 0.0f)
                        {
                        }
                        else if (area.left <= hpwf/2.0f)
                        {
                            points[4] = Point(area.left, hphf - hphf/4.0f + area.left/(hpwf/2.0f)*(hphf/4.0f));
                            points[5] = Point(area.left, hphf/4.0f - area.left/(hpwf/2.0f)*(hphf/4.0f));
                        }
                        else
                        {
                            points[5] = points[0] = Point(area.left, (area.left - hpwf/2.0f)/(hpwf/2.0f)*(hphf/4.0f));
                            points[4] = points[3] = Point(area.left, hphf - (area.left - hpwf/2.0f)/(hpwf/2.0f)*(hphf/4.0f));
                        }

                        if (_debug)
                            writefln("Left %s points: %s", area.left, points);

                        area.right++;
                        if (area.right >= hpwf)
                        {
                        }
                        else if (area.right >= hpwf/2.0f)
                        {
                            points[1] = Point(area.right, (area.right - hpwf/2.0f)/(hpwf/2.0f)*(hphf/4.0f));
                            points[2] = Point(area.right, hphf - (area.right - hpwf/2.0f)/(hpwf/2.0f)*(hphf/4.0f));
                        }
                        else
                        {
                            points[0] = points[1] = Point(area.right, hphf - hphf/4.0f + area.right/(hpwf/2.0f)*(hphf/4.0f));
                            points[2] = points[3] = Point(area.right, hphf/4.0f - area.right/(hpwf/2.0f)*(hphf/4.0f));
                        }

                        if (_debug)
                            writefln("Right %s points: %s", area.right, points);

                        Point[] p0, p3;

                        if (area.top <= 0.0f)
                        {
                        }
                        else if (area.top <= hphf/4.0f)
                        {
                            float x0 = hpwf/2.0f - area.top/(hphf/4.0f)*(hpwf/2.0f);
                            float x1 = hpwf/2.0f + area.top/(hphf/4.0f)*(hpwf/2.0f);
                            if (area.left < x0)
                                points[0] = Point(x0, area.top);
                            else
                                points[0] = points[5] = Point(area.left, area.top);

                            if (area.right > x1)
                                p0 ~= Point(x1, area.top);
                            else
                                points[1] = Point(area.right, area.top);
                        }
                        else if (area.top <= hphf - hphf/4.0f)
                        {
                            points[0] = points[5] = Point(area.left, area.top);
                            points[1] = Point(area.right, area.top);
                        }
                        else
                        {
                            float x0 = (area.top - (hphf - hphf/4.0f))/(hphf/4.0f)*(hpwf/2.0f);
                            float x1 = hpwf - (area.top - (hphf - hphf/4.0f))/(hphf/4.0f)*(hpwf/2.0f);

                            if (area.left < x0)
                                points[0] = points[5] = points[4] = Point(x0, area.top);
                            else
                                points[0] = points[5] = points[4] = Point(area.left, area.top);

                            if (area.right > x1)
                                points[1] = points[2] = Point(x1, area.top);
                            else
                                points[1] = points[2] = Point(area.right, area.top);
                        }

                        if (_debug)
                            writefln("Top %s points: %s, p0 %s", area.top, points, p0);

                        area.bottom++;
                        if (area.bottom >= hphf)
                        {
                        }
                        else if (area.bottom >= hphf - hphf/4.0f)
                        {
                            float x0 = hpwf/2.0f - (hphf - area.bottom)/(hphf/4.0f)*(hpwf/2.0f);
                            float x1 = hpwf/2.0f + (hphf - area.bottom)/(hphf/4.0f)*(hpwf/2.0f);

                            if (area.left < x0)
                                points[3] = Point(x0, area.bottom);
                            else
                                points[3] = points[4] = Point(area.left, area.bottom);

                            if (area.right > x1)
                                p3 ~= Point(x1, area.bottom);
                            else
                                points[2] = Point(area.right, area.bottom);
                        }
                        else if (area.bottom >= hphf/4.0f)
                        {
                            points[3] = points[2] = Point(area.right, area.bottom);
                            points[4] = Point(area.left, area.bottom);
                        }
                        else
                        {
                            float x0 = hpwf/2.0f + area.bottom/(hphf/4.0f)*(hpwf/2.0f);
                            float x1 = hpwf/2.0f - area.bottom/(hphf/4.0f)*(hpwf/2.0f);
                            
                            if (area.left < x0)
                                points[3] = points[2] = points[1] = Point(x0, area.bottom);
                            else
                                points[3] = points[2] = points[1] = Point(area.left, area.bottom);

                            if (area.right > x1)
                                points[4] = points[5] = Point(x1, area.bottom);
                            else
                                points[4] = points[5] = Point(area.right, area.bottom);
                        }

                        if (_debug)
                            writefln("Bottom %s points: %s, p3 %s", area.bottom, points, p3);

                        if (p0 !is null)
                            points = points[0..1] ~ p0 ~ points[1..6];
                        if (p3 !is null)
                            points = points[0..3] ~ p3 ~ points[3..6];

                        Point[] points2;

                        foreach (i, p; points)
                        {
                            if (p != points[(i+1)%$])
                                points2 ~= p;
                        }

                        swap(points, points2);


                        /*
                        if (lt)
                        {
                            points ~= Point(area.left, area.lefty0);
                            points ~= Point(area.topx0, area.top);
                        }
                        else
                        {
                            points ~= Point(area.left, area.top);
                        }

                        if (rt)
                        {
                            points ~= Point(area.topx1+1, area.top);
                            points ~= Point(area.right+1, area.righty0);
                        }
                        else
                        {
                            points ~= Point(area.right+1, area.top);
                        }

                        if (rb)
                        {
                            points ~= Point(area.right+1, area.righty1+1);
                            points ~= Point(area.bottomx1+1, area.bottom+1);
                        }
                        else
                        {
                            points ~= Point(area.right+1, area.bottom+1);
                        }

                        if (lb)
                        {
                            points ~= Point(area.bottomx0, area.bottom+1);
                            points ~= Point(area.left, area.lefty1+1);
                        }
                        else
                        {
                            points ~= Point(area.left, area.bottom+1);
                        }
                        */

                        if (points.length == 0)
                        {
                            ubyte[12] empty;
                            return empty;
                        }

                        if (_debug)
                            writefln("points: %s", points);

                        ubyte[] form;
                        {
                            float r = hph/2.0f;

                            foreach_reverse (p; points)
                            {
                                float x0 = p.x - hpw/2.0f;
                                float y0 = p.y - hph/2.0f;

                                float dr = hypot(x0, y0) + 0.1;
                                float angle = 1.5f - atan2(-y0, x0)*3.0f/PI;
                                if (angle < 0.0f) angle += 6.0f;
                                if (angle >= 6.0f) angle -= 6.0f;

                                int R = 4 - cast(int) round(4.0f*dr/r);
                                if (R < 0)
                                {
                                    R = 0;
                                    angle = (cast(int) round(angle))%6;
                                }

                                ubyte f = cast(ubyte) (R == 4 ? 60 : (27 - R*3)*R + (cast(int) round(angle*(4-R)))%(6*(4-R)));
                                form ~= f;

                                if (_debug)
                                    writefln("p=%s, R=%s (%s), A=%s, f=%s", p, R, 4.0f*dr/r, angle, f);
                            }
                        }

                        int first_c = -1;
                        int last_c = -1;

                        bool bdone;
                        int first_b = -1;
                        int nlast_b = -1;

                        ubyte[] form2;

                        foreach (i, f; form)
                        {
                            if (f != form[(i+1)%$])
                                form2 ~= f;
                        }

                        if (form2.length == 0) form2 ~= form[0];

                        swap(form, form2);

                        if (form.length > 2)
                        {
                            //normalize_form(form);

                            foreach_reverse (rotate; 0..6)
                            {
                                form2.length = 0;
                                foreach (i, f; form)
                                {
                                    if (rotate > 0)
                                    {
                                        if (f < 24)
                                        {
                                            f = cast(ubyte) ((f + 4*rotate)%24);
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

                                    form2 ~= f;
                                }

                                auto min = form2.minIndex();
                                form2 = form2[min..$] ~ form2[0..min];

                                if (form2[0] != form2[$-1])
                                    form2 ~= form2[0];

                                ubyte[12] f12;
                                foreach (i, f; form2)
                                {
                                    f12[i] = cast(ubyte) (f+1);
                                }

                                if (f12 in h6p_image.formsmap || rotate == 0)
                                {
                                    swap(form, form2);
                                    rot = cast(ubyte)((6-rotate)%6);
                                    break;
                                }
                            }
                        }
                        else
                        {
                            form = [];
                        }

                        if (_debug)
                        {
                            writefln("%sx%s: area = %s (%s), form = %s", x, y,
                                    area, area.calc_area(),
                                    form);

                            // @Pixel2HexAverage
                            for (int dy = 0; dy < hph; dy++)
                            {
                                for (int dx = 0; dx < hpw; dx++)
                                {
                                    // @HyperMask
                                    if ((*hp)[dx + dy*hpw])
                                    {
                                        write( indexed[dx + dy*hpw] == index ? '+' : '.' );
                                    }
                                    else write(' ');
                                }

                                writeln();
                            }

                            writeln();
                        }

                        ubyte[12] f12;
                        foreach (i, f; form)
                        {
                            f12[i] = cast(ubyte) (f+1);
                        }

                        BitArray *hyp = hyperpixel(hpw, f12, rot, _debug);

                        for (int dy = 0; dy < hph; dy++)
                        {
                            for (int dx = 0; dx < hpw; dx++)
                            {
                                // @HyperMask
                                if ((*hp)[dx + dy*hpw])
                                {
                                    if ((*hyp)[dx + dy*hpw] && (indexed[dx + dy*hpw] == index) )
                                    {
                                        suc++;
                                    }
                                    else if ((*hyp)[dx + dy*hpw] && !(indexed[dx + dy*hpw] == index) )
                                    {
                                        err++;
                                    }
                                }
                            }
                        }

                        return f12;
                    }

                    ubyte rot;
                    int err, suc;
                    ubyte[12] f12 = get_form(area, indexed, cast(ubyte) index, rot, err, suc);

                    if (_debug)
                        writefln("err %s, suc %s", err, suc);
                    if (err/*/2*/ > suc*2 || err > 20)
                    {
                        immutable int MAXG = 10;
                        ubyte[] group = new ubyte[hpw*hph];
                        ubyte g;
                        byte s = cast(byte) (hpw/8);
                        ubyte[] groupmap = new ubyte[MAXG];

                        for (int dy = 0; dy < hph; dy++)
                        {
                            for (int dx = 0; dx < hpw; dx++)
                            {
                                // @HyperMask
                                if ((*hp)[dx + dy*hpw])
                                {
                                    if (indexed[dx + dy*hpw] == index)
                                    {
                                        ubyte mg;
                                        for (byte sy = cast(byte) (-s); sy <= 0; sy++)
                                        {
                                            if (dy+sy < 0) continue;
                                            for (byte sx = cast(byte) (-(sy==0?1:0)*s); sx <= (sy==0?1:0)*s; sx++)
                                            {
                                                if (dx+sx < 0 || dx+sx >= hpw) continue;

                                                ubyte gr = group[dx+sx + (dy+sy)*hpw];

                                                if ( gr > 0 )
                                                {
                                                    if (groupmap[gr] > 0)
                                                    {
                                                        if (mg == 0)
                                                            mg = groupmap[gr];
                                                        else if (mg < groupmap[gr])
                                                            groupmap[gr] = mg;
                                                    }
                                                }
                                            }
                                        }

                                        if (mg > 0)
                                            group[dx + dy*hpw] = mg;
                                        else
                                        {
                                            group[dx + dy*hpw] = ++g;
                                            if (g >= MAXG)
                                            {
                                                if (_debug)
                                                    writefln("g >= MAXG");
                                                break iarea;
                                            }
                                            groupmap[g] = g;
                                        }
                                    }
                                }
                            }
                        }

                        for (int dy = 0; dy < hph; dy++)
                        {
                            for (int dx = 0; dx < hpw; dx++)
                            {
                                ubyte gr = group[dx + dy*hpw];
                                if ( groupmap[gr] < gr )
                                {
                                    while (groupmap[groupmap[gr]] != groupmap[gr])
                                    {
                                        groupmap[gr] = groupmap[groupmap[gr]];
                                    }

                                    group[dx + dy*hpw] = groupmap[gr];
                                }
                            }
                        }

                        int[] ggcount = new int[MAXG];
                        Area[] garea = new Area[MAXG];

                        // @Pixel2HexAverage
                        for (int dy = 0; dy < hph; dy++)
                        {
                            for (int dx = 0; dx < hpw; dx++)
                            {
                                ubyte gr = group[dx + dy*hpw];
                                if (gr > 0)
                                {
                                    ggcount[gr]++;
                                    garea[gr].extend(dx, dy);
                                }
                            }
                        }
                        
                        foreach (gr, zarea; garea)
                        {
                            if (gr == 0 || groupmap[gr] != gr) continue;
                            if (ggcount[gr] < 4) continue;

                            if (_debug)
                                writefln("GROUP %s of %s", gr, g);

                            f12 = get_form(zarea, group, cast(ubyte) gr, rot, err, suc);

                            if (_debug)
                                writefln("err %s, suc %s", err, suc);
                            if (err/4 > suc || err < 10)
                            {
                                is_ok = false;
                                //break iarea;
                            }

                            ushort form_n = h6p_image.get_form_num(f12);

                            if (_debug)
                                writefln("%s. AForm %s rot %s", h6p_pixel.forms.length, form_n, rot);
                            if (form_n > 0 && h6p_pixel.forms.length < 7)
                                h6p_pixel.forms ~= SubForm(form_n, extra_color, rot);
                        }
                    }
                    else
                    {
                        ushort form_n = h6p_image.get_form_num(f12);

                        if (_debug)
                            writefln("%s. BForm %s rot %s", h6p_pixel.forms.length, form_n, rot);
                        if (form_n > 0 && h6p_pixel.forms.length < 7)
                            h6p_pixel.forms ~= SubForm(form_n, extra_color, rot);
                    }
                }

                if (is_ok)
                    ok++;
                else
                    fails++;
            }
            else
            {
                h6p_pixel.color = find_color_in_palette(ptree, hexpalette[0]);
            }
        }
    }

    writefln("Forms count %s", h6p_image.forms.length);
    writefln("%s ok, %s fails", ok, fails);

    return h6p_image;
}

/+
Vertex[] draw_line(H6P* h6p_image, Vertex v0, Vertex v1, Color fg, Color bg, byte width, byte layer = 0)
{
    assert(layer < 2);

    byte awidth = abs(width);

    Vertex[] vxs;

    float fx0, fy0;
    float fx1, fy1;

    to_float_coords(v0, fx0, fy0);
    to_float_coords(v1, fx1, fy1);

    float[3] eq;
    line_equation([fx0, fy0], [fx1, fy1], eq);

    writefln("v0 %s", v0);

    Vertex vc = v0;

    while (true)
    {
        byte choose_op(Vertex vc, out float mindist, out float mincdist)
        {
            byte op;

            mincdist = 1e10f;

            Vertex v = vc;
            foreach (byte side; 0..6)
            {
                //if (vc.p >= side*4 && (vc.p < (side+1)*4 || vc.p == ((side+1)*4)%24)) continue;

                v.p = cast(byte) (side*4);
                float sx1, sy1;
                to_float_coords(v, sx1, sy1);
                //writefln("side = %s, v = %s, sx1 = %s, sy1 = %s", side, v, sx1, sy1);

                v.p = ((side+1)*4)%24;
                float sx2, sy2;
                to_float_coords(v, sx2, sy2);
                //writefln("side = %s, v = %s, sx2 = %s, sy2 = %s", side, v, sx2, sy2);

                float[3] side_eq;
                line_equation([sx1, sy1], [sx2, sy2], side_eq);
                
                float[2] intersection;
                intersection_by_equation(eq, side_eq, intersection);

                bool between(float r, float a, float b)
                {
                    return b > a ? r >= a - 1e-1 && r <= b + 1e-1 : r >= b - 1e-1 && r <= a + 1e-1;
                }

                float dx = intersection[0] - fx1;
                float dy = intersection[1] - fy1;
                float cdist = hypot(dx, dy);
                //writefln("intersection %s, cdist = %s", intersection, cdist);
                //writefln("between1 %s, between2 %s", between(intersection[0], sx1, sx2), between(intersection[1], sy1, sy2));

                if (between(intersection[0], sx1, sx2) && between(intersection[1], sy1, sy2) && cdist < mincdist)
                {
                    mincdist = cdist;
                    //writefln("side %s cdist %s, side_eq %s", side, cdist, [sx1, sy1, sx2, sy2]);

                    mindist = 1e10f;

                    foreach (byte p; 0..5)
                    {
                        v.p = (side*4 + p) % 24;
                        float px, py;
                        to_float_coords(v, px, py);

                        float dist = hypot(px - intersection[0], py - intersection[1]);
                        if (dist < mindist)
                        {
                            mindist = dist;
                            op = v.p;
                            //writefln("op %s, dist %s", op, dist);
                        }
                    }
                }
            }

            return op;
        }

        float mindist, mincdist;
        byte op = choose_op(vc, mindist, mincdist);

        /*ubyte[4] p2 = [255, 0, 0, 255];
          Color pr2 = Color([0.0, 0.0, 0.0, 0.0], false, null);
          color_from_u8(p2, rgbspace, &pr2);
          Pixel h6ppixel2 = Pixel(pr2, 0, 0);
          set_pixel(h6p_image, xc+1, yc, &h6ppixel2, ErrCorrection.ORDINARY);
         */

        byte pp1 = vc.p;
        byte pp2 = op;

        bool invw;
        if (pp1 > pp2 && pp1 - pp2 < 12 || pp2 - pp1 > 12)
        {
            invw = true;
            swap(pp1, pp2);
        }

        bool sinv;
        ubyte form = form_by_p(pp1, pp2, sinv);

        int[][] neigh = new int[][](6, 2);
        // @H6PNeighbours
        neighbours(vc.x, vc.y, neigh);

        writefln("op %s, form = %s", op, form);

        Pixel h6ppixel = get_pixel(h6p_image, vc.x, vc.y);
        h6ppixel.color = fg;

        h6ppixel.form &= 0x0F00FF << ((1-layer)*8);
        h6ppixel.extra_color &= 0x0F << ((1-layer)*4);
        if (form > 0)
        {
            h6ppixel.form |= ((((width != 0 && (invw ^ (width > 0)) ? 0x8 : 0x0) | awidth) << 16) | form) << (layer*8);
            h6ppixel.extra_color |= (width == 0 && invw ? 0x8 : 0x0) << (layer*4);
        }
        else
        {
            form = form_by_p((pp1-width+24)%24, (pp2+width+24)%24, sinv);
            h6ppixel.form |= form << (layer*8);
            h6ppixel.extra_color |= 0x8 << (layer*4);
        }
        set_pixel(h6p_image, vc.x, vc.y, &h6ppixel, ErrCorrection.ORDINARY);

        vxs ~= vc;

        if (vc.x == v1.x && vc.y == v1.y) break;

        //float fxp, fyp; //DEBUG
        //to_float_coords(xc, yc, op, fxp, fyp); //DEBUG

        if (op%4 == 0)
        {
            auto ng1 = neigh[(op/4)%6];
            Vertex nv1 = Vertex(ng1[0], ng1[1], ((op/4+2)%6*4)%24);

            float mindist1, mincdist1;
            byte op1 = choose_op(nv1, mindist1, mincdist1);

            auto ng2 = neigh[(op/4 + 1)%6];
            Vertex nv2 = Vertex(ng2[0], ng2[1], ((op/4+3)%6*4 + 4)%24);

            float mindist2, mincdist2;
            byte op2 = choose_op(nv2, mindist2, mincdist2);

            writefln("nv1 %s mindist1 %s mincdist1 %s op1 %s, nv2 %s mindist2 %s mincdist2 %s op2 %s",
                    nv1, mindist1, mincdist1, op1, nv2, mindist2, mincdist2, op2);

            if (nv1.x == v1.x && nv1.y == v1.y)
            {
                vc = nv1;
            }
            else if (nv2.x == v1.x && nv2.y == v1.y)
            {
                vc = nv2;
            }
            else if (abs(mindist1 - mindist2) < 1e-1 && abs(mincdist1 - mincdist2) < 1e-1)
            {
                float fx, fy;
                to_float_coords(Vertex(nv1.x, nv1.y, 24), fx, fy);

                float dist = signed_dist_point_to_line([fx, fy], eq);

                writefln("signed dist for %s %s", Vertex(nv1.x, nv1.y, 24), dist);

                if (dist > 0.0f)
                {
                    vc = nv1;
                }
                else
                {
                    vc = nv2;
                }
            }
            else if (mincdist1 < mincdist2)
            {
                vc = nv1;
            }
            else
            {
                vc = nv2;
            }
        }
        else
        {
            auto n = neigh[(op/4 + 1)%6];
            vc = Vertex(n[0], n[1], ((op/4+3)%6*4 + 4-op%4)%24);
        }

        writefln("vc %s", vc);
        assert(vc.x < h6p_image.width && vc.y < h6p_image.height);

        //to_float_coords(xc, yc, nc, fxc, fyc); //DEBUG

        //assert(hypot(fxc-fxp, fyc-fyp) < 1e-2); //DEBUG
    }

    return vxs;
}

void draw_region(H6P* h6p_image, Vertex[] region, Color fg, Color bg, byte width = 0, byte layer = 0)
{
    Vertex[] vxs;

    if (region.length == 2)
        vxs ~= draw_line(h6p_image, region[0], region[1], fg, bg, width, layer);
    else
    {
        foreach(z, v1; region)
        {
            auto v2 = region[(z+1)%$];

            vxs ~= draw_line(h6p_image, v1, v2, fg, bg, width, layer);
        }

        if (width == 0)
        {
            foreach (z, v1; vxs)
            {
                auto v0 = vxs[(z-1+$)%$];
                auto v2 = vxs[(z+1)%$];

                if (v2.y < v1.y || v1.y < v0.y)
                {
                    uint x1 = uint.max;
                    foreach (dz; 2..vxs.length)
                    {
                        auto w0 = vxs[(z+dz-1+$)%$];
                        auto w1 = vxs[(z+dz)%$];
                        auto w2 = vxs[(z+dz+1)%$];

                        if (w1.y == v1.y && (w2.y > w1.y || w1.y > w0.y) && w1.x > v1.x && w1.x < x1)
                        {
                            x1 = w1.x;
                        }
                    }

                    if (x1 < uint.max)
                    {
                        //writefln("Start v1 %s - v2 %s till x1 = %s", v1, v2, x1);

                        foreach (x; v1.x+1..x1)
                        {
                            Pixel h6ppixel = get_pixel(h6p_image, x, v1.y);
                            h6ppixel.color = fg;
                            set_pixel(h6p_image, x, v1.y, &h6ppixel, ErrCorrection.ORDINARY);
                        }
                    }
                }
            }
        }
    }

    foreach (v; vxs)
    {
        int[][] neigh = new int[][](6, 2);
        // @H6PNeighbours
        neighbours(v.x, v.y, neigh);

        //writefln("form %s, width %s, extra_color %s",
        //        form, 0, 0x8 | extra_color);

        byte extra_color = -1;
        foreach (byte e; 0..6)
        {
            Pixel h6ppixel = get_pixel(h6p_image, neigh[e][0], neigh[e][1]);
            Color pc = h6ppixel.color;

            float cd = color_dist(&pc, &bg, ErrCorrection.ORDINARY);

            if (cd < 10.0f)
            {
                extra_color = e;
                if (v.x == 12) writefln("v %s e %s, neigh[e] = %s", v, e, neigh[e]);
                break;
            }

            /*cd = color_dist(&pc, &fg, ErrCorrection.ORDINARY);
            if (cd < 10.0f)
            {
                extra_color = 0x8 | e;
                if (v.x == 12) writefln("v %s inv e %s, neigh[e] = %s", v, e, neigh[e]);
                break;
            }*/
        }

        if (extra_color == -1)
        {
loop_e:
            foreach (byte e; 0..6)
            {
                Pixel h6ppixel = get_pixel(h6p_image, neigh[e][0], neigh[e][1]);
                if (h6ppixel.form == 0)
                {
                    int[][] neigh2 = new int[][](6, 2);
                    // @H6PNeighbours
                    neighbours(neigh[e][0], neigh[e][1], neigh2);

                    Color bc = h6ppixel.color;

                    foreach (byte e2; 0..6)
                    {
                        Pixel h6ppixel2 = get_pixel(h6p_image, neigh2[e2][0], neigh2[e2][1]);
                        Color pc = h6ppixel2.color;

                        float cd = color_dist(&pc, &bc, ErrCorrection.ORDINARY);

                        if (cd < 10.0f)
                        {
                            extra_color = e;

                            h6ppixel.color = bg;
                            h6ppixel.extra_color = cast(ubyte)((0x8 | e2) << (layer*4));
                            set_pixel(h6p_image, neigh[e][0], neigh[e][1], &h6ppixel, ErrCorrection.ORDINARY);
                            writefln("Ого! e %s, neigh[e] = %s, e2 %s, neigh2[e2]", e, neigh[e], e2, neigh[e2]);
                            break loop_e;
                        }
                    }
                }
            }
        }

        if (extra_color != -1)
        {
            Pixel h6ppixel = get_pixel(h6p_image, v.x, v.y);
            h6ppixel.extra_color &= (0xF << ((1-layer)*4)) | (0x8 << (layer*4));
            h6ppixel.extra_color ^= extra_color << (layer*4);
            if (extra_color & 0x8)
            {
                h6ppixel.color = bg;
            }
            set_pixel(h6p_image, v.x, v.y, &h6ppixel, ErrCorrection.ORDINARY);
        }
    }
}

H6P *test24(int scale, string space_name, ubyte[5] chw)
{
    // @Pixel2HexScaleUp
    int scaleup = 1;

    if (scale == 4 || scale == 2 || scale == 1)
    {
        scaleup = 8/scale;
        scale = 8;
    }       

    // @HyperPixelAnatomy
    int hpw = scale;
    float hpwf = hpw;
    float hphf = round(hpwf * 2.0 / sqrt(3.0));
    int hph = cast(int)hphf;

    bool hp24 = chw[4] == 4;

    // @HyperMaskFile
    string dir = "/tmp/hexpict/";
    string hpfile = dir ~ "hp"~hpw.text~"x"~hph.text~".areas"~(hp24 ? "24" : "");
    if (!hpfile.exists)
    {
        if ( ! (hp24 ? hyperpixel24(hpw) : hyperpixel(hpw)) )
        {
            assert(false, "Invalid scale " ~ scale.text);
        }
    }

    ubyte[] buffer = cast(ubyte[]) read(hpfile);
    ulong[] hp = cast(ulong[]) buffer;

    int hh = (hph+2)/4;

    int nw = 100;
    int nh = 64;

    ColorSpace *space = new ColorSpace;
    assert(space !is null);
    *space = cast(ColorSpace) SRGB_SPACE;

    switch(space_name)
    {
        case "RGB":
            space.type = ColorType.RGB;
            space.companding = CompandingType.GAMMA_2_2;
            space.alpha_companding = CompandingType.NONE;
            break;

        case "RMB":
            space.type = ColorType.RMB;
            space.companding = CompandingType.HLG;
            space.alpha_companding = CompandingType.NONE;

            float rm = 1.0029;
            space.bounds = new double[][3];
            for (size_t i = 0; i < 3; i++)
            {
                space.bounds[i] = new double[2];
            }
            space.bounds[0][0] = 0.0;
            space.bounds[0][1] = 0.0;
            space.bounds[0][2] = 0.0;
            space.bounds[1][0] = rm;
            space.bounds[1][1] = rm;
            space.bounds[1][2] = rm;
            break;

        case "LMS":
            space.type = ColorType.LMS;
            space.companding = CompandingType.GAMMA_2_2;
            space.alpha_companding = CompandingType.NONE;
            break;

        case "ITP":
            space.type = ColorType.ITP;
            space.companding = CompandingType.NONE;
            space.alpha_companding = CompandingType.NONE;

            space.bounds = new double[][3];
            for (size_t i = 0; i < 3; i++)
            {
                space.bounds[i] = new double[2];
            }
            itp_bounds_by_color_space(space, space.bounds);
            break;

        default:
            assert(false, "Unsupported color space");
    }
    
    calc_rgb_matrices(space);

    ColorSpace *rgbspace = get_rgbspace(space);

    H6P* h6p_image = h6p_create(space, chw, nw, nh);

    for (int y = 0; y < nh; y++)
    {
        for (int x = 0; x < nw; x++)
        {
            ubyte[4] p = [255, 255, 255, 255];
            Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
            color_from_u8(p, rgbspace, &pr);

            Pixel h6ppixel = Pixel(pr, 0, 0);

            set_pixel(h6p_image, x, y, &h6ppixel, ErrCorrection.ORDINARY);
        }
    }

    enum TESTNUM = 2;

    static if (TESTNUM == 0)
    {
        int form = 1;
        foreach(py; 0..3)
        {
            foreach(px; 0..2)
            {
                foreach(s; 0..4)
                {
                    foreach(f; 5..12+s+1)
                    {
                        //int form = (p0*38 + s*(15+s)/2 + f-5);
                        uint x = 1+(px * 12 + f-5)*2;
                        uint y = 1+(py * 5 + s)*2;

                        ubyte[4] p = [255, 128, 0, 255];
                        Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                        color_from_u8(p, rgbspace, &pr);

                        //writefln("x %s y %s form %s", x, y, form);
                        Pixel h6ppixel = Pixel(pr, form | (0<<16) | (1<<8) | (0 << 20), 5 | (3 << 4));

                        set_pixel(h6p_image, x, y, &h6ppixel, ErrCorrection.ORDINARY);

                        p = [255, 0, 0, 255];
                        pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                        color_from_u8(p, rgbspace, &pr);
                        h6ppixel = Pixel(pr, 0, 0);
                        set_pixel(h6p_image, x-1, y, &h6ppixel, ErrCorrection.ORDINARY);

                        p = [0, 128, 255, 255];
                        pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                        color_from_u8(p, rgbspace, &pr);
                        h6ppixel = Pixel(pr, 0, 0);
                        set_pixel(h6p_image, x+1, y+1, &h6ppixel, ErrCorrection.ORDINARY);

                        form++;
                    }
                }
            }
        }
    }
    else static if (TESTNUM == 1)
    {
        int p0 = 0;
        foreach(s; 0..4)
        {
            int p1 = p0*4 + s;
            foreach(f; 5..12+s+1)
            {
                int p2 = (p0*4+f)%24;

                foreach(d; 0..(24-(f-s))/2)
                {
                    int pp1 = (p1 + 24 - d)%24;
                    int pp2 = (p2 + d)%24;
                    bool inv;
                    if (pp1 > pp2 && pp1 - pp2 < 12 || pp2 - pp1 > 12)
                    {
                        inv = true;
                        swap(pp1, pp2);
                    }
                    if (pp1/4 == (pp2-1)/4) break;
                    int pp0 = pp1/4;
                    int ss = pp1%4;
                    int ff = (pp2 - pp0*4 + 24)%24;

                    int form = 1 + (pp0*38 + ss*(15+ss)/2 + ff-5);

                    int P = (form-1)/38;
                    int f38 = (form-1)%38;
                    int F, S;
                    if (f38 < 8) { S = 0; F = 5+f38; }
                    else if (f38 < 8+9) { S = 1; F = 5+f38-8; }
                    else if (f38 < 8+9+10) { S = 2; F = 5+f38-8-9; }
                    else { S = 3; F = 5+f38-8-9-10; }

                    assert(P==pp0 && F==ff && S == ss);

                    uint x = 1+((f-5)%3*12 + d)*2;
                    uint y = 1+(s*5 + (f-5)/3)*2;

                    ubyte[4] p = [255, 128, 0, 255];
                    Color pr = Color([0.0, 0.0, 0.0, 0.0], false, null);
                    color_from_u8(p, rgbspace, &pr);

                    //writefln("x %s y %s form %s", x, y, form);
                    Pixel h6ppixel = Pixel(pr, form, 3 | (inv ? 8 : 0));

                    set_pixel(h6p_image, x, y, &h6ppixel, ErrCorrection.ORDINARY);
                }
            }
        }
    }
    else static if (TESTNUM == 2)
    {
        ubyte[4] p = [255, 128, 0, 255];
        Color fg;
        color_from_u8(p, rgbspace, &fg);

        p = [255, 255, 255, 255];
        Color bg;
        color_from_u8(p, rgbspace, &bg);

        uint x0 = 30;
        uint y0 = 30;
        uint r = 25;
        Vertex[] region;
        foreach(z; [1, 3, 5, 2, 4])
        {
            float xf = x0 + r*sin(72.0f/180.0f*PI*z);
            float yf = y0 - r*cos(72.0f/180.0f*PI*z);

            uint y = cast(uint) round(yf);
            uint x = cast(uint) round(xf - (y%2 == 1 ? 0.5f : 0.0f));

            region ~= Vertex(x, y, 0);
        }

        writefln("star region %s", region);
        draw_region(h6p_image, region, fg, bg, 1);

        //draw_region(h6p_image, [Vertex(10, 10, 0), Vertex(30, 20, 0), Vertex(50, 12, 0), Vertex(40, 30, 6), Vertex(50, 50, 12), Vertex(30, 40, 12), Vertex(10, 52, 12), Vertex(20, 32, 18)], fg, bg, 1);
        //draw_region(h6p_image, [Vertex(10, 10, 2), Vertex(50, 50, 10)], fg, bg);

        p = [0, 128, 255, 255];
        color_from_u8(p, rgbspace, &fg);

        draw_region(h6p_image, [Vertex(62, 61, 16), Vertex(83, 55, 16)], fg, bg, 1);
        //draw_region(h6p_image, [Vertex(10, 10, 2), Vertex(50, 50, 10), Vertex(50, 50, 12), Vertex(10, 10, 0)], fg, bg);
        //draw_region(h6p_image, [Vertex(50, 50, 12), Vertex(10, 10, 0)], fg, bg);
    }

    return h6p_image;
}
+/
