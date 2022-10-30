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

module tools.hex2pixel;

import std.stdio;
import std.conv;

import hexpict.hex2pixel;
import hexpict.hyperpixel;

/*
 * Prints usage info. We are using it in hex2pixel() function
 * when see errors in passed to the program arguments.
 */
private void usage()
{
    writeln("Usage: hex2pixel [options] <from-file.h6p> <to-file.png>");
    writeln("   Renders h6p-file into png picture.");
    writeln("   where options:");
    writeln("   -s, --scale <num> -- size of used hyperpixel (3, 4 or more)");
    writeln("                        --scalelist for full list available sizes");
    writeln("                        default 4.");
    writeln("   -l, --scalelist   -- List of available scales");
}

/*
 * Main function of hex2pixel tool gets arguments of command line.
 * See description of arguments in the usage() above.
 */
int hex2pixel(string[] args)
{
    string fromfile, tofile;
    int scale = 4;

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

            case "-l":
            case "--scalelist":
                scalelist();
                return 0;

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

    hexpict.hex2pixel.hex2pixel(fromfile, tofile, scale);

    return 0;
}

