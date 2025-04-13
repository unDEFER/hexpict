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

module tools.pixel2hex;

import std.stdio;
import std.conv;
import std.string;
import bindbc.sdl;
import sdl_image;

import hexpict.color;
import hexpict.h6p;
import hexpict.pixel2hex;
import hexpict.hexogrid;
import hexpict.hyperpixel;

/*
 * Prints usage info. We are using it in pixel2hex() function
 * when see errors in passed to the program arguments.
 */
private void usage()
{
    writeln("Usage: pixel2hex [options] <from-file.png> <to-file.h6p>");
    writeln("   Converts png picture to h6p-file.");
    writeln("   where options:");
    writeln("   -s, --scale <num> -- down-scale into times (1, 3 or 4)");
    writeln("                        default 4.");
}

/*
 * Main function of pixel2hex tool gets arguments of command line.
 * See description of arguments in the usage() above.
 */
int pixel2hex(string[] args)
{
    string fromfile, tofile;
    int scale = 4;

    int ww = 16;

    {
        ubyte[12] form12 = [30, 55, 31, 30, 0, 0, 0, 0, 0, 0, 0, 0];
        hyperpixel(ww, form12, 0);
    }

    /*
    {
        ubyte[12] form12 = [1, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        hyperpixel(ww, form12, 0);
        hyperpixel(ww, form12, 1);
        hyperpixel(ww, form12, 2);
    }

    {
        ubyte[12] form12 = [13, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        hyperpixel(ww, form12, 0);
        hyperpixel(ww, form12, 1);
        hyperpixel(ww, form12, 2);
    }

    {
        ubyte[12] form12 = [13, 1, 5, 9, 13, 0, 0, 0, 0, 0, 0, 0];
        hyperpixel(ww, form12, 0);
        hyperpixel(ww, form12, 1);
        hyperpixel(ww, form12, 2);
    }

    {
        ubyte[12] form12 = [1, 54, 20, 51, 15, 49, 11, 47, 6, 44, 1, 0];
        hyperpixel(ww, form12, 0);
        hyperpixel(ww, form12, 1);
        hyperpixel(ww, form12, 2);
        hyperpixel(ww, form12, 3);
    }

    {
        ubyte[12] form12 = [1, 44, 6, 47, 11, 49, 15, 51, 20, 54, 1, 0];
        hyperpixel(ww, form12, 0);
        hyperpixel(ww, form12, 5);
        hyperpixel(ww, form12, 4);
    }
    */

    int i = 1;
    loop:
    while (i < args.length)
    {
        switch (args[i])
        {
            case "-s":
            case "--scale":
                scale = args[i+1].to!(int);
                i++;
                break;

            default:
                break loop;
        }

        i++;
    }

    if (args.length < i+2)
    {
        writefln("Wrong numbers of arguments");
        usage();
        return 1;
    }

    fromfile = args[i];
    tofile = args[i+1];

    rmb_init();

    int flags = IMG_Init(
        IMG_INIT_JPG
        | IMG_INIT_PNG
        | IMG_INIT_TIF
        //| IMG_INIT_WEBP
        //| IMG_INIT_JXL
        //| IMG_INIT_AVIF
    );
    assert (flags & IMG_INIT_PNG);

    SDL_Surface *image = IMG_Load(fromfile.toStringz());
    writefln("%s", fromStringz(SDL_GetError()));
    assert(image !is null);

    /*SDL_Surface *im = hexogrid(image, scale, 2.0, 10, 10, 1024, 768, 5, 5);
    SDL_SaveBMP(im, tofile.toStringz());
    SDL_FreeSurface(im);*/

    H6P *h6p_image = hexpict.pixel2hex.pixel2hex(image, scale, "ITP");
    SDL_FreeSurface(image);

    h6p_write(h6p_image, tofile);

    return 0;
}

