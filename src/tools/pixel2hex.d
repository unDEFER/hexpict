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

import hexpict.pixel2hex;

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
    writeln("                        default 3.");
    writeln("   -d, --debug       -- writes debug_hex.png and debug_mask.png");
    writeln("                        files.");
}

/*
 * Main function of pixel2hex tool gets arguments of command line.
 * See description of arguments in the usage() above.
 */
int pixel2hex(string[] args)
{
    string fromfile, tofile;
    int scale = 3;
    bool dbg;

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

            case "-d":
            case "--debug":
                dbg = true;
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

    hexpict.pixel2hex.pixel2hex(fromfile, tofile, scale, dbg);
    return 0;
}

