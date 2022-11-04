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

import imaged;
import hexpict.color;

import std.bitmanip;
import std.math;
import std.file;
import std.stdio;

private
{
    uint[Pixel] color_map;
    Pixel[] color_pal;

    int color_num;

    /*
     * Generates optimal palette
     * @OptimalPalette
     */
    void generate_palette()
    {
        color_pal = new Pixel[2^^18];

        int num = 135; // 261838 colors
        color_num = num;

        writefln("Generate palette");
        uint colors = 1;
        uint collisions = 0;
        foreach (z; 0..num)
        {
            foreach (y; num/4..num-num/4+1)
            {
                foreach (x; 0..num)
                {
                    ITP I = ITP(x/(num-1.0), -0.5 + y/(num-1.0), -0.5 + z/(num-1.0));
                    RGB P = ITP2RGB(I);

                    if (P.r < 0.0 || P.r > 255.5 || P.g < 0.0 || P.g > 255.5 || P.b < 0.0 || P.b > 255.5)
                        continue;
                    ITP I2 = RGB2ITP(P);
                    if ( abs(I2.I-I.I) > 0.001 || abs(I2.T-I.T) > 0.001 || abs(I2.P-I.P) > 0.001 )
                        continue;

                    Pixel p = RGB2rgb(P);
                    if (p in color_map)
                    {
                        collisions++;
                    }
                    else
                    {
                        color_pal[colors] = p;
                        color_map[p] = colors;
                        colors++;
                    }
                }
            }
        }

        writefln("Size of palette: %s colors", colors);
        writefln("%s collisions", collisions);
    }
}

/*
 * Writes h6p-file
 * @H6PFormat
 */
void write_h6p(Image image, Image mask, string h6p_file)
{
    if (color_pal.length == 0) generate_palette();

    uint fileversion = 2;
    uint w = image.width;
    uint h = image.height;

    ubyte[] content = new ubyte[16 + w*h*4];

    content[0..4] = cast(ubyte[]) "HexP";
    content[4..8] = nativeToBigEndian(fileversion);
    content[8..12] = nativeToBigEndian(w);
    content[12..16] = nativeToBigEndian(h);

    foreach (y; 0..h)
    {
        foreach (x; 0..w)
        {
            uint pix;
            Pixel p = image[x, y];
            Pixel m = mask[x, y];

            ITP I = rgb2ITP(p);

            I.I = round(I.I * (color_num-1.0))/(color_num-1.0);
            I.T = round((I.T+.5) * (color_num-1.0))/(color_num-1.0) - .5;
            I.P = round((I.P+.5) * (color_num-1.0))/(color_num-1.0) - .5;

            RGB pc = ITP2RGB(I);
            int dr, dg, db;
            while (pc.r < 0 || pc.g < 0 || pc.b < 0 ||
                    pc.r > 255 || pc.g > 255 || pc.b > 255)
            {
                if (pc.r < 0) dr++;
                if (pc.g < 0) dg++;
                if (pc.b < 0) db++;

                if (pc.r > 255) dr--;
                if (pc.g > 255) dg--;
                if (pc.b > 255) db--;

                Pixel p1 = Pixel(p.r+dr, p.g+dg, p.b+db);
                I = rgb2ITP(p1);

                I.I = round(I.I * (color_num-1.0))/(color_num-1.0);
                I.T = round((I.T+.5) * (color_num-1.0))/(color_num-1.0) - .5;
                I.P = round((I.P+.5) * (color_num-1.0))/(color_num-1.0) - .5;

                pc = ITP2RGB(I);
                //writefln("%s", pc);
            }

            Pixel pc0 = RGB2rgb(pc);

            /*
            if (pc0 !in color_map)
                writefln("%s not in map (%s) %s/%s/%s", pc0, I,
                        round(I.I * (color_num-1.0)),
                        round((I.T+.5) * (color_num-1.0)),
                        round((I.P+.5) * (color_num-1.0)));
            */
            uint color = color_map[pc0];
            //writefln("%s => %s,%s,%s | %s", p, r, g, b, color);

            pix |= (color & 0x3FFFF) << 14;
            pix |= (cast(ubyte) m.g & 0x03) << 10;
            pix |= (cast(ubyte) m.r & 0xFF) << 4;
            pix |= (cast(ubyte) m.b & 0x0F);

            content[16+(y*w+x)*4..16+(y*w+x+1)*4] = nativeToBigEndian(pix);
        }
    }

    std.file.write(h6p_file, content);
}

/*
 * Reads h6p-file
 * @H6PFormat
 */
void read_h6p(string h6p_file, ref Image image, ref Image mask)
{
    if (color_pal.length == 0) generate_palette();

    ubyte[] content = cast(ubyte[]) read(h6p_file);
    
    char[] magic = cast(char[]) content[0..4];
    assert(magic == "HexP", "Wrong magic number, not `h6p` file");

    uint fileversion = bigEndianToNative!uint(content[4..8]);
    assert(fileversion == 2, "Wrong file version");

    uint w = bigEndianToNative!uint(content[8..12]);
    uint h = bigEndianToNative!uint(content[12..16]);

    ubyte[] imgdata = new ubyte[w*h*3];
    ubyte[] maskdata = new ubyte[w*h*3];

    foreach (y; 0..h)
    {
        foreach (x; 0..w)
        {
            uint pix;
            ubyte[4] bytes;
            bytes = content[16+(y*w+x)*4..16+(y*w+x+1)*4];
            pix = bigEndianToNative!uint(bytes);

            uint color = cast(uint) ((pix >> 14) & 0x3FFFF);

            Pixel p = color_pal[color];

            imgdata[(y*w + x)*3 + 0] = cast(ubyte) p.r;
            imgdata[(y*w + x)*3 + 1] = cast(ubyte) p.g;
            imgdata[(y*w + x)*3 + 2] = cast(ubyte) p.b;

            maskdata[(y*w + x)*3 + 1] = (pix >> 10) & 0x03;
            maskdata[(y*w + x)*3 + 0] = (pix >> 4) & 0xFF;
            maskdata[(y*w + x)*3 + 2] = pix & 0x0F;
        }
    }

    image = new Img!(Px.R8G8B8)(w, h, imgdata);
    mask = new Img!(Px.R8G8B8)(w, h, maskdata);
}
