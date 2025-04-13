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

module hexpict.hexogrid;

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

enum DBGX = 858;
enum DBGY = 181;

SDL_Surface *hexogrid(SDL_Surface *image, uint scale, float scaleup, int offx, int offy, int ow, int oh, int selx, int sely)
{   
    // @HyperMask
    uint w = scale;
    float wf = w;
    float hf = round(wf * 2.0 / sqrt(3.0));
    uint h = cast(uint) hf;

    ubyte[12] form12;
    BitArray *hp = hyperpixel(w, form12, 0);

    int iw = image.w;
    int ih = image.h;

    uint hpw = scale;
    float hpwf = hpw;
    float hphf = round(hpwf * 2.0 / sqrt(3.0));
    uint hph = cast(uint) hphf;

    float hhf = floor(hphf/4.0);
    uint hh = cast(uint) hhf;

    int nw = cast(int) ceil(iw * scaleup / hpw);
    int nh = cast(int) ceil(ih * scaleup / (hph-hh));

    ubyte[] imgbuf;

    int oow = cast(int) ceil(ow * scaleup / hpw);
    int ooh = cast(int) ceil(oh * scaleup / (hph-hh));

    int th = min(nh, offy+ooh-1);
    int tw = min(nw, offx+oow);

    imgbuf = new ubyte[ow*oh*4];
    assert(imgbuf !is null);

    ColorSpace *space = new ColorSpace;
    assert(space !is null);
    *space = cast(ColorSpace) SRGB_SPACE;

    space.type = ColorType.RGB;
    space.companding = CompandingType.GAMMA_2_2;
    space.alpha_companding = CompandingType.NONE;

    calc_rgb_matrices(space);

    ColorSpace *rgbspace = get_rgbspace(space);

    for (int y0 = 0; y0 < oh; y0++)
    {
        int y = offy + y0/(hph-hh);

        for (int x0 = 0; x0 < ow; x0++)
        {
            int x = offx + (x0 - (y%2 == 1?hpw/2:0))/hpw;

            int hx = (y%2 == 1?hpw/2:0) + (x-offx)*hpw;
            int hx2 = hx + hpw/2;
            int hy = (y-offy)*(hph-hh);
            int hy2 = hy + hh;

            float hw = hpwf;

            int dx = x0 - hx2;
            int dy = y0 - hy;

            if (y0 < hy2)
            {
                hw = 1.0f*dy*hpw/hh;

                if (abs(dx) > hw/2.0f)
                {
                    hy -= (hph-hh);
                    if (dx > 0) hx = hx2;
                    else hx -= hpw/2;

                    hx2 = hx + hpw/2;
                    dx = x0 - hx2;
                    dy = y0 - hy;
                    hw = hpw - hw;
                }
            }

            bool bdr = (abs(dx) >= (hw/2.0f - 1.0f));

            int sx0 = cast(int) round(x0/scaleup);
            int sy0 = cast(int) round(y0/scaleup);

            // @Pixel2HexScaleUp
            if (sx0 < iw && sy0 < ih)
            {
                uint pixel_value;
                ubyte *pixel = cast(ubyte*) (image.pixels + sy0 * image.pitch + sx0 * image.format.BytesPerPixel);
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

                bool sel = (x == selx && y == sely);
                if (bdr)
                {
                    if (dx < 0)
                    {
                        if (!sel) r = cast(ubyte) (r < 205 ? r + 50 : 255);
                        g = cast(ubyte) (g < 205 ? g + 50 : 255);
                        if (!sel) b = cast(ubyte) (b < 205 ? b + 50 : 255);
                    }
                    else
                    {
                        if (!sel) r = cast(ubyte) (r > 50 ? r - 50 : 0);
                        g = cast(ubyte) (g > 50 ? g - 50 : 0);
                        if (!sel) b = cast(ubyte) (b > 50 ? b - 50 : 0);
                    }
                }

                ubyte[4] p = [r, g, b, a];

                uint off = (y0*ow + x0)*4;
                imgbuf[off..off+4] = p;
            }
        }
    }

    uint rmask, gmask, bmask, amask;
    rmask = 0x000000ff;
    gmask = 0x0000ff00;
    bmask = 0x00ff0000;
    amask = 0xff000000;
    return SDL_CreateRGBSurfaceFrom(imgbuf.ptr, ow, oh,
            32, ow * 4, rmask, gmask, bmask, amask);
}
