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

module hexpict.color;

import std.math;

import imaged;

struct RGB
{
    double r = 0.0;
    double g = 0.0;
    double b = 0.0;
}

/*
 * Gamma correction with gamma = 2.2
 * See https://en.wikipedia.org/wiki/Gamma_correction
 * for details
 */
RGB gamma(Pixel P)
{
    double gamma = 2.2;
    double r = (P.r/255.0)^^gamma * 255.0;
    double g = (P.g/255.0)^^gamma * 255.0;
    double b = (P.b/255.0)^^gamma * 255.0;

    return RGB(r, g, b);
}

/*
 * Gamma correction with gamma = 2.2
 * See https://en.wikipedia.org/wiki/Gamma_correction
 * for details
 */
RGB gamma(RGB P)
{
    double gamma = 2.2;
    double r = (P.r/255.0)^^gamma * 255.0;
    double g = (P.g/255.0)^^gamma * 255.0;
    double b = (P.b/255.0)^^gamma * 255.0;

    return RGB(r, g, b);
}

/*
 * Inverse of gamma correction with gamma = 2.2
 * See https://en.wikipedia.org/wiki/Gamma_correction
 * for details
 */
RGB invgamma(RGB P)
{
    double gamma = 1.0/2.2;
    double r = (P.r/255.0)^^gamma * 255.0;
    double g = (P.g/255.0)^^gamma * 255.0;
    double b = (P.b/255.0)^^gamma * 255.0;

    // @RGBNaN
    if ( isNaN(r) ) r = -1.0;
    if ( isNaN(g) ) g = -1.0;
    if ( isNaN(b) ) b = -1.0;

    return RGB(r, g, b);
}

struct LMS
{
    double L, M, S;
}

struct ICtCp
{
    double I, Ct, Cp;
}

struct ITP
{
    double I = 0.0;
    double T = 0.0;
    double P = 0.0;
}

/*
 * Convert color from RGB color space to LMS.
 * https://en.wikipedia.org/wiki/LMS_color_space for details
 */
LMS rgb2lms(RGB p)
{
    double L = (1688.0*p.r + 2146.0*p.g + 262.0*p.b)/255.0/4096.0;
    double M = (683.0*p.r + 2951.0*p.g + 462.0*p.b)/255.0/4096.0;
    double S = (99.0*p.r + 309.0*p.g + 3688.0*p.b)/255.0/4096.0;
    return LMS(L, M, S);
}

/*
 * Convert color from RGB color space to LMS with gamma correction.
 */
LMS rgb2lms(Pixel p)
{
    RGB r = gamma(p);
    LMS l = rgb2lms(r);

    return l;
}

/*
 * Convert color from LMS color space to RGB.
 * https://en.wikipedia.org/wiki/LMS_color_space for details
 */
RGB lms2rgb(LMS p)
{
    double R = (   3.4366*p.L - 2.506452*p.M + 0.0698454*p.S)*255.0;
    double G = ( -0.79133*p.L + 1.983600*p.M - 0.1922709*p.S)*255.0;
    double B = (-0.025950*p.L -0.0989137*p.M + 1.1248636*p.S)*255.0;
    return RGB(R, G, B);
}

/*
 * Convert color from LMS color space to ICtCp
 * https://en.wikipedia.org/wiki/LMS_color_space and
 * https://en.wikipedia.org/wiki/ICtCp for details
 */
ICtCp LMS2ICtCp(LMS p)
{
    double I  = (2048.0*p.L +  2048.0*p.M + 0.0*p.S)/4096.0;
    double Ct = (3625.0*p.L - 7465.0*p.M + 3840.0*p.S)/4096.0;
    double Cp = (9500.0*p.L - 9212.0*p.M - 288.0*p.S)/4096.0;
    return ICtCp(I, Ct, Cp);
}

/*
 * Convert color from ICtCp color space to LMS
 * https://en.wikipedia.org/wiki/LMS_color_space and
 * https://en.wikipedia.org/wiki/ICtCp for details
 */
LMS ICtCp2LMS(ICtCp p)
{
    double L = (1.0*p.I + 0.01571858*p.Ct + 0.209581068*p.Cp);
    double M = (1.0*p.I - 0.01571858*p.Ct - 0.209581068*p.Cp);
    double S = (1.0*p.I + 1.02127108*p.Ct - 0.605274491*p.Cp);
    // @LMSNaN
    if (M < 0) M = double.nan;
    if (S < 0) S = double.nan;
    return LMS(L, M, S);
}

/*
 * The hybrid log–gamma (HLG) transfer function.
 * https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma for details
 */
double hlg(double E)
{
    double a = 0.17883277;
    double b = 0.28466892;
    double c = 0.55991073;

    if (E <= 1.0/12.0)
        return sqrt(3.0*E);
    else
        return a*log(12.0*E - b) + c;
}

/*
 * Inverse of the hybrid log–gamma (HLG) transfer function.
 * https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma for details
 */
double inv_hlg(double Es)
{
    double a = 0.17883277;
    double b = 0.28466892;
    double c = 0.55991073;

    if (Es <= 0.5)
        return Es*Es/3.0;
    else
        return (exp((Es - c) / a) + b)/12.0;
}

/*
 * HLG-transfer function for color in LMS color space
 */
LMS hlg(LMS p)
{
    p.L = hlg(p.L);
    p.M = hlg(p.M);
    p.S = hlg(p.S);
    return p;
}

/*
 * Inverse of HLG-transfer function for color in LMS color space
 */
LMS inv_hlg(LMS p)
{
    p.L = inv_hlg(p.L);
    p.M = inv_hlg(p.M);
    p.S = inv_hlg(p.S);
    return p;
}

/*
 * Convert color in RGB color space to ITP
 * https://en.wikipedia.org/wiki/ICtCp for details
 */
ITP rgb2ITP(Pixel p)
{
    RGB r = gamma(p);
    LMS l = rgb2lms(r);
    l = hlg(l);
    ICtCp i = LMS2ICtCp(l);
    return ITP(i.I, 0.5*i.Ct, i.Cp);
}

/*
 * Convert color in RGB color space to ITP
 * https://en.wikipedia.org/wiki/ICtCp for details
 */
ITP RGB2ITP(RGB p)
{
    RGB r = gamma(p);
    LMS l = rgb2lms(r);
    l = hlg(l);
    ICtCp i = LMS2ICtCp(l);
    return ITP(i.I, 0.5*i.Ct, i.Cp);
}

/*
 * Convert color in ITP color space to RGB
 * https://en.wikipedia.org/wiki/ICtCp for details
 */
RGB ITP2RGB(ITP I)
{
    ICtCp i = ICtCp(I.I, 2.0*I.T, I.P);
    LMS l = ICtCp2LMS(i);
    l = inv_hlg(l);
    RGB r = lms2rgb(l);
    r = invgamma(r);
    return r;
}

/*
 * Convert and round RGB in double-precision floating-point
 * to integer format
 */
Pixel RGB2rgb(RGB r)
{
    return Pixel(cast(ushort) round(r.r),
                 cast(ushort) round(r.g),
                 cast(ushort) round(r.b),
                 255);
}

/*
 * Convert color in ITP color space to RGB
 * with rounding to integer format
 */
Pixel ITP2rgb(ITP I)
{
    RGB r = ITP2RGB(I);

    return RGB2rgb(r);
}

/*
 * Color difference in ITP color space
 * https://en.wikipedia.org/wiki/Color_difference#Rec._ITU-R_BT.2124_or_%CE%94EITP for details
 */
double color_diff(Pixel a, Pixel b)
{
    ITP i1 = rgb2ITP(a);
    ITP i2 = rgb2ITP(b);

    double dI = i1.I - i2.I;
    double dT = i1.T - i2.T;
    double dP = i1.P - i2.P;

    return 720.0*sqrt(dI*dI + dT*dT + dP*dP);
}
