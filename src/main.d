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

// @Story

module main;

import std.stdio;
import std.path;

import tools.pixel2hex;
import tools.hex2pixel;
import tools.h6pinfo;

/*
 * Prints usage info. We are using it in main() function
 * when see errors in passed to the program arguments.
 */
private void usage()
{
    writeln("Usage: hexpict <tool> [options]");
    writeln("   where <tool> is `pixel2hex`, `hex2pixel` or `h6pinfo`");
}

/*
 * Main function gets arguments of command line.
 * `hexpict` utility is agregate of 2 tools "pict2hex" and "hex2pict".
 * The name of tool passed to the program as the first argument
 *   or as name of symbolic link to the main program.
 */
int main(string[] args)
{
    // @ZeroArgument
    size_t tool_narg = 0;
    
    if (args[0].baseName() == "hexpict")
    {
        tool_narg = 1;
        if (args.length < 2)
        {
            writefln("Wrong number of arguments");
            usage();
            return 1;
        }
    }

    switch (args[tool_narg].baseName())
    {
        case "pixel2hex":
            return pixel2hex(args[tool_narg..$]);
    
        case "hex2pixel":
            return hex2pixel(args[tool_narg..$]);

        case "h6pinfo":
            return h6pinfo(args[tool_narg..$]);
    
        default:
            usage();
            return 1;
    }
}

