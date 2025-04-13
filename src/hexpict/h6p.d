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

module hexpict.h6p;

import hexpict.color;
import hexpict.colors;
import hexpict.hyperpixel;

import std.bitmanip;
import std.math;
import std.file;
import std.stdio;
import std.algorithm.mutation;
import std.zlib;

struct SubForm
{
    ushort form; // 11 bits
    ushort extra_color; // 10 bits
    ubyte rotation; // 3 bits

    ubyte[3] encode()
    {
        uint code24;
        code24 |= (cast(uint) form & 0x7FF) << 21;
        code24 |= (cast(uint) extra_color & 0x3FF) << 11;
        code24 |= (cast(uint) rotation & 0x7) << 8;
        ubyte[4] be32_code = nativeToBigEndian(cast(uint) code24);
        return be32_code[0..3];
    }

    void decode(ubyte[] code)
    {
        assert(code.length == 3);
        ubyte[4] be32_code;
        be32_code[0..3] = code[0..3];
        uint code24 = bigEndianToNative!uint(be32_code);
        form = code24 >> 21;
        extra_color = (code24 >> 11) & 0x3FF;
        rotation = (code24 >> 8) & 0x7;
    }
}

// @H6PPixel
struct Pixel
{
    ubyte palette; // 3 bits
    ushort color; // 10 bits
    SubForm[] forms; // (len) 3 bits

    ubyte[2] encode()
    {
        assert(forms.length < 8);

        ushort code;
        code |= (cast(ushort) (palette & 0x7)) << 13;
        code |= (color & 0x3FF) << 3;
        code |= (cast(ushort) forms.length & 0x7);
        ubyte[2] be16_code = nativeToBigEndian(cast(ushort) code);
        return be16_code;
    }

    void decode(ubyte[] be16_code)
    {
        assert(be16_code.length == 2);
        ushort code = bigEndianToNative!ushort(be16_code[0..2]);
        palette = code >> 13;
        color = (code >> 3) & 0x3FF;
        forms.length = code & 0x7;
    }
};

struct Form
{
    ubyte[12] dots;
    uint used;
    BitArray*[6] hp;
    int last_w;

    BitArray* get_hyperpixel(int w, ubyte rotate)
    {
        if (hp[rotate] is null || last_w != w)
        {
            hp[rotate] = hyperpixel(w, dots, rotate);
            last_w = w;
        }

        return hp[rotate];
    }

    ubyte[9] encode()
    {
        ubyte[9] code;

        for (int i = 0; i < 3; i++)
        {
            uint code24;
            code24 |= (cast(uint) dots[4*i+0] & 0x3F) << 26;
            code24 |= (cast(uint) dots[4*i+1] & 0x3F) << 20;
            code24 |= (cast(uint) dots[4*i+2] & 0x3F) << 14;
            code24 |= (cast(uint) dots[4*i+3] & 0x3F) << 8;
            ubyte[4] be32_code = nativeToBigEndian(cast(uint) code24);
            code[3*i .. 3*i+3] = be32_code[0..3];
        }
        return code;
    }

    void decode(ubyte[] code)
    {
        assert(code.length == 9);
        for (int i = 0; i < 3; i++)
        {
            ubyte[4] be32_code;
            be32_code[0..3] = code[3*i .. 3*i+3];
            uint code24 = bigEndianToNative!uint(be32_code);
            dots[4*i+0] = code24 >> 26;
            dots[4*i+1] = (code24 >> 20) & 0x3F;
            dots[4*i+2] = (code24 >> 14) & 0x3F;
            dots[4*i+3] = (code24 >> 8) & 0x3F;
        }
    }
}

// @H6PInMemory
struct H6P
{
    ColorSpace *space;
    uint width;
    uint height;
    ubyte[][8] palette;
    Color[][8] cpalette;
    Form[] forms;
    Pixel[] raster;

    ushort[ubyte[12]] formsmap;

    ushort get_form_num(ubyte[12] dots)
    {
        if (dots[0] < 4 && dots[1] > 4 && dots[1] < 24 && dots[2] == 0)
        {
            return cast(ushort) (1 + dots[0]*19 + (dots[1] - 5));
        }

        ushort *num = dots in formsmap;
        if (num !is null) return cast(ushort) (19*4 + *num);

        if (forms.length >= 1972) return 0;

        forms ~= Form(dots);
        formsmap[dots] = cast(ushort) (forms.length - 1);
        return cast(ushort) (19*4 + forms.length - 1);
    }

    Pixel *pixel(uint x, uint y)
    {
        assert(x < width);
        assert(y < height);
        uint off = y*width + x;

        return &raster[off];
    }
};

H6P* h6p_create(ColorSpace *space, uint w, uint h)
{
    H6P* h6p = new H6P;
    assert(h6p !is null);

    h6p.space = space;
    h6p.width = w;
    h6p.height = h;
    h6p.palette[0] = new ubyte[2*4];
    h6p.cpalette[0] ~= Color([0.0f, 0.0f, 0.0f, 0.0f], false, space);
    h6p.raster = new Pixel[w*h];
    assert(h6p.raster !is null);

    return h6p;
}

/*
 * Writes h6p-file
 * @H6PFormat
 */
void h6p_write(H6P *h6p, string h6p_file)
{
    string space_name;
    const RgbBaseColors *basep = &h6p.space.base;
    switch (h6p.space.type)
    {
        case ColorType.RGB:
            space_name = "RGB";
            break;
        case ColorType.RMB:
            space_name = "RMB";
            break;
        case ColorType.LMS:
            space_name = "LMS";
            break;
        case ColorType.ITP:
            space_name = "ITP";
            break;
        default:
            assert(false, "Unsupported color space");
    }

    uint fileversion = 2;
    uint w = h6p.width;
    uint h = h6p.height;

    ubyte[60] header;

    header[0..4] = cast(ubyte[]) "HEDU";

    ubyte[4] be32_fileversion = nativeToBigEndian(fileversion);
    ubyte[4] be32_w = nativeToBigEndian(w);
    ubyte[4] be32_h = nativeToBigEndian(h);

    header[4..8] = be32_fileversion;
    header[8..12] = be32_w;
    header[12..16] = be32_h;
    header[16..19] = cast(ubyte[]) space_name[0..3];

    RgbBaseColors base;
    base = *basep;

    float xw, yw;
    float xr, yr;
    float xg, yg;
    float xb, yb;
    xw = base.w.x; yw = base.w.y;
    xr = base.r.x; yr = base.r.y;
    xg = base.g.x; yg = base.g.y;
    xb = base.b.x; yb = base.b.y;

    float[8] basec = [xw, yw, xr, yr, xg, yg, xb, yb];

    size_t off = 20;
    for (uint i = 0; i < 8; i++)
    {
        float b = basec[i];
        uint bu32 = cast(uint) (b * pow(2.0, 32.0));
        ubyte[4] be32_b = nativeToBigEndian(bu32);
        header[off..off+4] = be32_b;
        off += 4;
    }

    // @H6PSections
    ubyte[] data;

    foreach (i, palette; h6p.palette)
    {
        writefln("Palette %s, size %s", i, h6p.cpalette[i].length);
        ubyte[2] be16_psize = nativeToBigEndian(cast(ushort) h6p.cpalette[i].length);
        data ~= be16_psize;

        data ~= palette;
    }

    ubyte[2] be16_fcount = nativeToBigEndian(cast(ushort) h6p.forms.length);
    data ~= be16_fcount;

    foreach (form; h6p.forms)
    {
        data ~= form.encode();
    }

    uint dbgoff = 60*w + 298;
    foreach (pixel; h6p.raster)
    {
        data ~= pixel.encode();
    }

    foreach (o, pixel; h6p.raster)
    {
        foreach (f, form; pixel.forms)
        {
            if (o == dbgoff)
                writefln("%s. Form %s, rot %s", f, form.form, form.rotation);
            data ~= form.encode();
        }
    }
    
    writefln("data len %s", data.length);

    ubyte[] compressed_data;

    compressed_data = compress(data);
    assert(compressed_data !is null);

    writefln("Compression ratio: %s%%, size %s bytes", compressed_data.length*100/data.length, compressed_data.length);
    ubyte[8] be64_c = nativeToBigEndian(cast(ulong) compressed_data.length);
    header[52..52+8] = be64_c;

    auto f = File(h6p_file, "w");
    f.rawWrite(header);

    f.rawWrite(compressed_data);
}

void itp_bounds_by_color_space(ColorSpace *space, ref Bounds itp_bounds)
{
    switch (space.type)
    {
        case ColorType.RGB:
            get_itp_bounds(space, itp_bounds);
            break;

        case ColorType.RMB:
        case ColorType.LMS:
        case ColorType.ITP:
            get_itp_bounds(&RMB_SPACE, itp_bounds);
            break;
        
        default:
            assert(false, "Unreachable statement");
    }
}

H6P *h6p_read(string h6p_file)
{
    ubyte[] content = cast(ubyte[]) read(h6p_file);

    char[4] magic = cast(char[]) content[0..4];
    assert(magic == "HEDU");

    uint fileversion = bigEndianToNative!uint(content[4..8]);
    assert(fileversion == 2, "Unsupported version");

    uint w = bigEndianToNative!uint(content[8..12]);
    uint h = bigEndianToNative!uint(content[12..16]);
    char[3] space_name = cast(char[]) content[16..19];

    float[8] base;
    uint off = 20;
    for (uint i = 0; i < 8; i++)
    {
        ubyte[4] be_base = content[off..off+4];
        base[i] = bigEndianToNative!uint(be_base) / pow(2.0, 32.0);
        off += 4;
    }

    XyType wh = XyType(base[0], base[1]);
    XyType r = XyType(base[2], base[3]);
    XyType g = XyType(base[4], base[5]);
    XyType b = XyType(base[6], base[7]);

    RgbBaseColors basecolors = RgbBaseColors(wh, r, g, b);
    ColorSpace *space = new ColorSpace;
    assert(space !is null);
    space.base = basecolors;
    space.rgb_companding = CompandingType.GAMMA_2_2;
    space.rgba_companding = CompandingType.NONE;
    space.bounds = null;
    space.rgb_matrices = null;

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
            space.bounds = new double[][](2, 3);
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

            space.bounds = new double[][](2, 3);
            itp_bounds_by_color_space(space, space.bounds);
            break;

        default:
            assert(false, "Unsupported color space");
    }

    calc_rgb_matrices(space);

    ubyte[8] be_size = content[52 .. 52 + 8];
    ulong compressed_size = bigEndianToNative!ulong(be_size);

    ulong offset = 60;

    ubyte[] data = cast(ubyte[]) uncompress(content[offset..offset + compressed_size]);

    H6P *h6p = new H6P;
    assert(h6p !is null);

    h6p.space = space;
    h6p.width = w;
    h6p.height = h;

    off = 0;
    foreach (i, ref palette; h6p.palette)
    {
        ubyte[2] be16_psize = data[off..off+2];
        ushort psize = bigEndianToNative!ushort(be16_psize);

        off += 2;
        palette = data[off..off + psize*4*2];

        Color[] cpalette;
        foreach(p; 0..psize)
        {
            float[4] channels;
            foreach (j, ref ch; channels)
            {

                ubyte[2] be16_ch = palette[p*8 + j*2 .. p*8 + j*2 + 2];
                ushort chs = bigEndianToNative!ushort(be16_ch);
                ch = chs / 65535.0f;
            }

            cpalette ~= Color(channels, false, space);
        }
        h6p.cpalette[i] = cpalette;

        off += psize*4*2;
    }

    ubyte[2] be16_fcount = data[off..off+2];
    ushort fcount = bigEndianToNative!ushort(be16_fcount);

    off += 2;
    h6p.forms.length = fcount;
    foreach (f, ref form; h6p.forms)
    {
        form.decode(data[off..off+9]);
        h6p.formsmap[form.dots] = cast(ushort) f;
        off += 9;
    }

    h6p.raster.length = w*h;
    uint dbgoff = 60*w + 298;
    foreach (ref pixel; h6p.raster)
    {
        pixel.decode(data[off..off+2]);
        off += 2;
    }

    foreach (o, ref pixel; h6p.raster)
    {
        foreach (f, ref form; pixel.forms)
        {
            form.decode(data[off..off+3]);
            if (o == dbgoff)
                writefln("%s. Form %s, rot %s", f, form.form, form.rotation);
            if (form.form > 19*4) h6p.forms[form.form - 19*4].used++;
            off += 3;
        }
    }

    return h6p;
}


