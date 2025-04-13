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

module tools.h6pinfo;

import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.bitmanip;
import std.math;

import hexpict.h6p;
import hexpict.color;

/*
 * Prints usage info. We are using it in hex2pixel() function
 * when see errors in passed to the program arguments.
 */
private void usage()
{
    writeln("Usage: h6pinfo <file1.h6p> [<file2.h6p> ...]");
    writeln("   Show h6p-file info.");
}

bool info(string h6p_file)
{
    ubyte[] content = cast(ubyte[]) read(h6p_file);

    char[4] magic = cast(char[]) content[0..4];
    if (magic != "HexP" && magic != "HEDU")
    {
        writefln("Not h6p/hedu file");
        return false;
    }

    uint fileversion = bigEndianToNative!uint(content[4..8]);
    writefln("%s file, version %d", (magic == "HexP" ? "h6p" : "hedu"), fileversion);

    if (!(magic == "HexP" && fileversion == 3) && !(magic == "HEDU" && fileversion == 1))
    {
        return false;
    }

    uint w = bigEndianToNative!uint(content[8..12]);
    uint h = bigEndianToNative!uint(content[12..16]);

    writef("Size %dx%d", w, h);

    char[3] space_name = cast(char[]) content[16..19];

    writefln(", Color Space %s", space_name);

    ubyte[5] chw = content[19..24];

    uint pixw = 0;
    for (size_t i = 0; i < 5; i++)
    {
        pixw += chw[i];
    }

    float[8] base;
    uint off = 24;
    for (uint i = 0; i < 8; i++)
    {
        ubyte[4] be_base = content[off..off+4];
        base[i] = bigEndianToNative!uint(be_base) / pow(2.0, 32.0);
        off += 4;
    }

    ulong[5] compressed_size;
    ubyte[][5] section_data;

    for (size_t s = 0; s < 5; s++)
    {
        ubyte[8] be_size = content[56 + s*8..56 + (s+1)*8];
        compressed_size[s] = bigEndianToNative!ulong(be_size);
    }

    for (size_t i = 0; i < 5; i++)
    {
        if (chw[i] > 0)
        {
            writefln("Compression ratio %s: %s%%, size %s bytes", i, compressed_size[i]*100/(w*h * chw[i]), compressed_size[i]);
        }
    }

    return true;
}

/*
 * Main function of hex2pixel tool gets arguments of command line.
 * See description of arguments in the usage() above.
 */
int h6pinfo(string[] args)
{
    if (args.length < 2)
    {
        writefln("Wrong numbers of arguments");
        usage();
        return 1;
    }
    
    int i = 1;
    loop:
    while (i < args.length)
    {
        writef("%s: ", args[i]);
        info(args[i]);
        i++;
    }
    

    return 0;
}

