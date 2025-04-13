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
import std.conv;
import hexpict.colors;

alias double[][] Bounds;

enum ColorType
{
    RGB = 0,
    RMB,
    XYZ,
    XYY,
    YUV,
    LAB,
    LMS,
    ICTCP,
    ITP
}

enum CompandingType
{
    NONE = 0,
    SRGB,
    L, // L* Companding
    HLG,
    GAMMA_1_8 = 18,
    GAMMA_2_2 = 22,
    GAMMA_2_6 = 26
}

struct XyType
{
    float x;
    float y;
}

struct RgbBaseColors
{
    XyType w;
    XyType r;
    XyType g;
    XyType b;
};

struct ColorSpace
{
    ColorType type;
    CompandingType companding;
    CompandingType alpha_companding;
    CompandingType rgb_companding;
    CompandingType rgba_companding;
    RgbBaseColors base;
    XyzMatrices *rgb_matrices;
    Bounds bounds;
};

struct Color
{
    float[4] channels;
    bool error;

    const (ColorSpace) *space;
};

struct XyzMatrices
{
    float[9] to_xyz;
    float[9] from_xyz;
};

struct Mixer
{
    Color *color;
    int num;
};

ColorSpace RMB_RGBSPACE;

enum ErrCorrection
{
    ORDINARY,
    DOUBLE
};

float max3(float[3] v)
{
    float max = v[0];
    if (v[1] > max) { max = v[1]; }
    if (v[2] > max) { max = v[2]; }
    return max;
}

float min3(float[3] v)
{
    float min = v[0];
    if (v[1] < min) { min = v[1]; }
    if (v[2] < min) { min = v[2]; }
    return min;
}

float dist3(float[3] v1, float[3] v2)
{
    float d0 = v2[0] - v1[0];
    float d1 = v2[1] - v1[1];
    float d2 = v2[2] - v1[2];

    return sqrt(d0*d0 + d1*d1 + d2*d2);
}

void mix3(float[3] v1, float[3] v2, float alpha, float *v)
{
    v[0] = v1[0]*(1.0-alpha) + v2[0]*alpha;
    v[1] = v1[1]*(1.0-alpha) + v2[1]*alpha;
    v[2] = v1[2]*(1.0-alpha) + v2[2]*alpha;
}           

void inverse_matrix3(float[9] m, ref float[9] v)
{
    float a, b, c, d, e, f, g, h, i;
    a = m[0]; b = m[1]; c = m[2];
    d = m[3]; e = m[4]; f = m[5];
    g = m[6]; h = m[7]; i = m[8];

    float A, B, C, D, E, F, G, H, I;
    A = e*i-f*h; B = f*g-d*i; C = d*h-e*g;
    D = c*h-b*i; E = a*i-c*g; F = b*g-a*h;
    G = b*f-c*e; H = c*d-a*f; I = a*e-b*d;

    float det = a*A + b*B + c*C;

    assert(det != 0.0, "zero determinant");

    v[0] = A/det; v[1] = D/det; v[2] = G/det;
    v[3] = B/det; v[4] = E/det; v[5] = H/det;
    v[6] = C/det; v[7] = F/det; v[8] = I/det;
    assert(!isNaN(v[0]));
}

float piecewise_gaussian(float x, float mu, float sigma1, float sigma2)
{
    return x < mu ?
        exp(-0.5*pow((x-mu)/sigma1, 2.0)) :
        exp(-0.5*pow((x-mu)/sigma2, 2.0));
}

float companding(float e, CompandingType type)
{
    switch(type)
    {
        case CompandingType.NONE:
            return e;

        case CompandingType.SRGB:
        {
            if (e < 0.0031308)
            {
                return 12.92*e;
            }
            else
            {
                return 1.055 * pow(e, 1.0/2.4) - 0.055;
            }
        }

        case CompandingType.L:
        {
            if (e < 0.008856)
            {
                return e*9.033;
            }
            else
            {
                return 1.16*pow(e, 1.0/3.0) - 0.16;
            }
        }

        case CompandingType.HLG:
        {
            /*
             * The hybrid log–gamma (HLG) transfer function.
             * https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma for details
             */
            float a = 0.17883277;
            float b = 0.28466892;
            float c = 0.55991073;

            if (e <= 1.0/12.0)
            {
                return sqrt(3.0*e);
            }
            else
            {
                return a*log(12.0*e - b) + c;
            }
        }

        /*
         * Gamma correction
         * See https://en.wikipedia.org/wiki/Gamma_correction
         * for details
         */
        default:
            return pow(e, 10.0/type);
    }
}

float inv_companding(float es, CompandingType type)
{
    switch(type)
    {
        case CompandingType.NONE:
            return es;

        case CompandingType.SRGB:
        {
            if (es < 0.04045)
            {
                return es / 12.92;
            }
            else
            {
                return pow((es+0.055)/1.055, 2.4);
            }
        }

        case CompandingType.L:
        {
            if (es < 0.08)
            {
                return es / 9.033;
            }
            else
            {
                return pow((es+0.16)/1.16, 3.0);
            }
        }

        case CompandingType.HLG:
        {
            /*
             * Inverse of the hybrid log–gamma (HLG) transfer function.
             * https://en.wikipedia.org/wiki/Hybrid_log%E2%80%93gamma for details
             */
            float a = 0.17883277;
            float b = 0.28466892;
            float c = 0.55991073;

            if (es <= 0.5)
            {
                return es*es/3.0;
            }
            else
            {
                return (exp((es - c) / a) + b)/12.0;
            }
        }

        default:
            return pow(es, type/10.0);
    }
}

// https://jcgt.org/published/0002/02/01/paper.pdf
// cie 1931
void xyy_color_matching(float lambda, Color* color)
{
    float x = 1.056*piecewise_gaussian(lambda, 599.8, 37.88, 30.96) +
        0.362*piecewise_gaussian(lambda, 442.0, 16.03, 26.74) -
        0.065*piecewise_gaussian(lambda, 501.1, 20.41, 26.18);

    float y = 0.821*piecewise_gaussian(lambda, 568.8, 46.95, 40.49) +
        0.286*piecewise_gaussian(lambda, 530.9, 16.31, 31.06);

    float z = 1.217*piecewise_gaussian(lambda, 437.0, 11.83, 35.97) +
        0.681*piecewise_gaussian(lambda, 459.0, 25.97, 13.79);

    color.channels[0] = x;
    color.channels[1] = y;
    color.channels[2] = z;
    color.error = false;
    color.space = &XYZ_SPACE;

    color_convert(color, &XYY_SPACE, ErrCorrection.ORDINARY);
}

void calc_rgb_matrices(ColorSpace *space)
{
    if (space.rgb_matrices !is null)
        return;

    float xr, yr, zr;
    xr = space.base.r.x;
    yr = space.base.r.y;
    zr = 1.0 - xr - yr;

    float xg, yg, zg;
    xg = space.base.g.x;
    yg = space.base.g.y;
    zg = 1.0 - xg - yg;

    float xb, yb, zb;
    xb = space.base.b.x;
    yb = space.base.b.y;
    zb = 1.0 - xb - yb;

    float[9] m1 = [xr, xg, xb,
                   yr, yg, yb,
                   zr, zg, zb];

    float[9] m2;
    assert(!m1[0].isNaN());

    inverse_matrix3(m1, m2);
    assert(!m2[0].isNaN());

    float rx, ry, rz;
    float gx, gy, gz;
    float bx, by, bz;

    rx = m2[0]; ry = m2[1]; rz = m2[2];
    gx = m2[3]; gy = m2[4]; gz = m2[5];
    bx = m2[6]; by = m2[7]; bz = m2[8];

    float xw, yw, zw;
    xw = space.base.w.x;
    yw = space.base.w.y;
    zw = 1.0-xw-yw;

    xw *= 1.0/yw;
    zw *= 1.0/yw;
    yw = 1.0;

    float rw = rx*xw + ry*yw + rz*zw;
    float gw = gx*xw + gy*yw + gz*zw;
    float bw = bx*xw + by*yw + bz*zw;

    m1[0] = xr*rw; m1[1] = xg*gw; m1[2] = xb*bw;
    m1[3] = yr*rw; m1[4] = yg*gw; m1[5] = yb*bw;
    m1[6] = zr*rw; m1[7] = zg*gw; m1[8] = zb*bw;

    m2[0] = rx/rw; m2[1] = ry/rw; m2[2] = rz/rw;
    m2[3] = gx/gw; m2[4] = gy/gw; m2[5] = gz/gw;
    m2[6] = bx/bw; m2[7] = by/bw; m2[8] = bz/bw;

    space.rgb_matrices = new XyzMatrices();
    assert(space.rgb_matrices !is null);
    assert(!m1[0].isNaN());
    assert(!m2[0].isNaN());
    space.rgb_matrices.to_xyz = m1;
    space.rgb_matrices.from_xyz = m2;
}

float search_lambda(float lambda1, float lambda2, bool plus2pi, float cangle)
{
    assert(lambda2 != lambda1);
    //D65 white point
    float xw = 0.3127;
    float yw = 0.3290;

    float lambda = (lambda1 + lambda2)/2.0;

    float lambda11 = (lambda1 + lambda)/2.0;
    float lambda22 = (lambda2 + lambda)/2.0;

    Color xyy1, xyy2, xyy3;
    xyy_color_matching(lambda11, &xyy1);
    xyy_color_matching(lambda22, &xyy2);
    xyy_color_matching(lambda, &xyy3);

    float x1, x2, x3, y1, y2, y3;
    x1 = xyy1.channels[0];
    y1 = xyy1.channels[1];

    x2 = xyy2.channels[0];
    y2 = xyy2.channels[1];

    x3 = xyy3.channels[0];
    y3 = xyy3.channels[1];

    float dx1, dy1;
    float dx2, dy2;
    float dx3, dy3;

    dx1 = x1-xw; dy1 = y1-yw;
    dx2 = x2-xw; dy2 = y2-yw;
    dx3 = x3-xw; dy3 = y3-yw;

    float angle1 = atan2(dy1, dx1);
    float angle2 = atan2(dy2, dx2);
    float angle3 = atan2(dy3, dx3);

    if (plus2pi)
    {
        if (angle1 < 0.0)
        {
            angle1 += 2.0*PI;
        }

        if (angle2 < 0.0)
        {
            angle2 += 2.0*PI;
        }

        if (angle3 < 0.0)
        {
            angle3 += 2.0*PI;
        }
    }

    float dist1 = abs(cangle-angle1);
    float dist2 = abs(cangle-angle2);
    float dist3 = abs(cangle-angle3);

    //printf("cangle=%.3f\n", cangle);
    //printf("angle=%.3f, %.3f, %.3f\n", angle1, angle2, angle3);
    //printf("dist=%.3f, %.3f, %.3f\n", dist1, dist2, dist3);
    if (dist3 < 1e-5)
    {
        return lambda;
    }

    if (dist3 < dist1 && dist3 < dist2)
    {
        return search_lambda(lambda11, lambda22, plus2pi, cangle);
    }
    else if (dist1 < dist2)
    {
        return search_lambda(lambda1, lambda, plus2pi, cangle);
    }
    else
    {
        return search_lambda(lambda2, lambda, plus2pi, cangle);
    }
}

float[25304] Lambdas;

void precalculate_lambdas()
{
    float lb = 440.0;
    float lr = 650.0;

    for (int a = 0; a < 25304; a++)
    {
        float af = (a - 711) / 100.0;
        float l1 = search_lambda(lr, lb, a>811, af / 180.0 * PI);
        Lambdas[a] = l1;
    }
}

void rmb_init()
{
    float lb = 444.44;
    float lr = 645.16;
    float lg = 519.401;

    Color r, g, b;
    xyy_color_matching(lr, &r);
    xyy_color_matching(lg, &g);
    xyy_color_matching(lb, &b);
    RMB_RGBSPACE.base.w = D65_WHITE_COLOR;

    RMB_RGBSPACE.type = ColorType.RGB;
    RMB_RGBSPACE.companding = CompandingType.NONE;
    RMB_RGBSPACE.alpha_companding = CompandingType.NONE;
    RMB_RGBSPACE.rgb_companding = CompandingType.NONE;
    RMB_RGBSPACE.rgba_companding = CompandingType.NONE;
    RMB_RGBSPACE.base.r.x = r.channels[0];
    RMB_RGBSPACE.base.r.y = r.channels[1];
    RMB_RGBSPACE.base.g.x = g.channels[0];
    RMB_RGBSPACE.base.g.y = g.channels[1];
    RMB_RGBSPACE.base.b.x = b.channels[0];
    RMB_RGBSPACE.base.b.y = b.channels[1];

    calc_rgb_matrices(&RMB_RGBSPACE);
    
    precalculate_lambdas();
}

void get_itp_bounds_side(const(ColorSpace) *space, uint side, ref Bounds itp_bounds)
{
    Bounds bounds =[cast(double[3])[1.0, 1.0, 1.0], [0.0, -1.0, -1.0]];
    float[3] rgb = [0.0, 0.0, 0.0];

    uint z = side;
    uint np = z/2;
    uint vv = z%2;

    rgb[np] = vv;
    uint p1 = (np + 1)%3;
    uint p2 = (np + 2)%3;

    for (uint a = 0; a < 1024; a++)
    {
        rgb[p1] = a / 1024.0;
        for (uint b = 0; b < 1024; b++)
        {
            rgb[p2] = b / 1024.0;

            Color itp;
            itp.channels[0..3] = rgb;
            itp.channels[3] = 1.0;
            itp.error = false;
            itp.space = space;
            color_convert(&itp, &ITP_SPACE, ErrCorrection.ORDINARY);

            for (uint i = 0; i < 3; i++)
            {
                if (itp.channels[i] < bounds[0][i])
                {
                    bounds[0][i] = itp.channels[i];
                }

                if (itp.channels[i] > bounds[1][i])
                {
                    bounds[1][i] = itp.channels[i];
                }
            }
        }
    }

    itp_bounds[0] = bounds[0];
    itp_bounds[1] = bounds[1];
}

void get_itp_bounds(const ColorSpace *space, ref Bounds itp_bounds)
{
    Bounds bounds = [cast(double[3])[1.0, 1.0, 1.0], [0.0, -1.0, -1.0]];
    float[3] rgb = [0.0, 0.0, 0.0];

    for (uint z = 0; z < 12; z++)
    {
        uint p = z/4;
        uint vv = z%4;
        uint v1 = vv >> 1;
        uint v2 = vv & 1;

        uint n1 = (p + 1)%3;
        uint n2 = (p + 2)%3;

        rgb[n1] = v1;
        rgb[n2] = v2;

        for (uint pi = 0; pi < 10000; pi++)
        {
            rgb[p] = pi / 10000.0;

            Color itp;
            itp.channels[0..3] = rgb;
            itp.channels[3] = 1.0;
            itp.error = false;
            itp.space = space;
            color_convert(&itp, &ITP_SPACE, ErrCorrection.ORDINARY);

            for (uint i = 0; i < 3; i++)
            {
                if (itp.channels[i] < bounds[0][i])
                {
                    bounds[0][i] = itp.channels[i];
                }

                if (itp.channels[i] > bounds[1][i])
                {
                    bounds[1][i] = itp.channels[i];
                }
            }
        }
    }

    if (space !is &RMB_RGBSPACE)
    {
        Bounds side_bounds = new double[][](2, 3);
        get_itp_bounds_side(space, 2, side_bounds);

        if (side_bounds[1][1] > bounds[1][1])
        {
            bounds[1][1] = side_bounds[1][1] + 1e-7;
        }
    }

    assert(bounds[1][0] > bounds[0][0]);
    assert(bounds[1][1] > bounds[0][1]);
    assert(bounds[1][2] > bounds[0][2]);
    itp_bounds[0] = bounds[0];
    itp_bounds[1] = bounds[1];
}

bool base_cmp(const(RgbBaseColors) *a, const(RgbBaseColors) *b)
{
    return a.w.x == b.w.x && a.w.y == b.w.y &&
           a.r.x == b.r.x && a.r.y == b.r.y &&
           a.g.x == b.g.x && a.g.y == b.g.y &&
           a.b.x == b.b.x && a.b.y == b.b.y;
}

void color_from_u8(ubyte[4] c, ColorSpace *space, Color *h6p)
{
    h6p.channels[0] = c[0] / 255.0;
    h6p.channels[1] = c[1] / 255.0;
    h6p.channels[2] = c[2] / 255.0;
    h6p.channels[3] = c[3] / 255.0;
    h6p.error = false;
    h6p.space = space;
}

void color_to_u8(Color *h6p, ColorSpace *rgbspace, ref ubyte[4] col, bool *err, ErrCorrection correction)
{
    color_convert(h6p, rgbspace, correction);

    float max = max3(h6p.channels[0..3]);

    if (max > 1.0)
    {
        *err = true;

        if (correction == ErrCorrection.ORDINARY)
        {
            col[0] = cast(ubyte) round(h6p.channels[0]/max*255.0);
            col[1] = cast(ubyte) round(h6p.channels[1]/max*255.0);
            col[2] = cast(ubyte) round(h6p.channels[2]/max*255.0);
        }
        else if (correction == ErrCorrection.DOUBLE)
        {
            col[0] = cast(ubyte) round(h6p.channels[0]/max/max*255.0);
            col[1] = cast(ubyte) round(h6p.channels[1]/max/max*255.0);
            col[2] = cast(ubyte) round(h6p.channels[2]/max/max*255.0);
        }
        else
        {
            assert(0);
        }
    }
    else
    {
        col[0] = cast(ubyte) round(h6p.channels[0]*255.0);
        col[1] = cast(ubyte) round(h6p.channels[1]*255.0);
        col[2] = cast(ubyte) round(h6p.channels[2]*255.0);
    }

    col[3] = cast(ubyte) round(h6p.channels[3]*255.0);
}

bool prepare_positive(ref float[3] v, ErrCorrection correction)
{
    bool err = false;

    float min = min3(v);
    if (min < 0.0)
    {
        err = true;
        if (correction == ErrCorrection.ORDINARY)
        {
            v[0] -= min;
            v[1] -= min;
            v[2] -= min;
        }
        else if (correction == ErrCorrection.DOUBLE)
        {
            v[0] -= 2.0*min;
            v[1] -= 2.0*min;
            v[2] -= 2.0*min;
        }
        else
        {
            assert(0);
        }
    }

    return err;
}

ColorSpace *get_rgbspace(ColorSpace *spc)
{
    if (spc.type == ColorType.RGB) return spc;

    ColorSpace *space = new ColorSpace();
    assert(space !is null);
    space.type = ColorType.RGB;
    space.companding = spc.rgb_companding;
    space.alpha_companding = spc.rgba_companding;
    space.rgb_companding = spc.rgb_companding;
    space.rgba_companding = spc.rgba_companding;
    space.base = spc.base;
    space.rgb_matrices = spc.rgb_matrices;
    space.bounds = null;
    calc_rgb_matrices(space);

    return space;
}

float lab_c(float fc, float cn)
{
    float delta = 6.0/29.0;

    float c;
    if (fc > delta)
    {
        c = cn * pow(fc, 3.0);
    }
    else
    {
        c = (fc - 16.0/116.0) * 3.0 * delta*delta * cn;
    }

    return c;
}

float calc_lambda(float cangle)
{
    float angl = (cangle*180.0/PI + 7.11)*100.0;
    float a1 = floor(angl);
    float t = angl - a1;

    uint a1u = cast(uint) a1;
    uint a2u = a1u + 1;

    float l1 = Lambdas[a1u];
    float l2 = Lambdas[a2u];

    return l1 + (l2-l1)*t;
}

void line_equation(float[2] p1, float[2] p2, ref float[3] res)
{
    float x1, y1;
    float x2, y2;
    x1 = p1[0]; y1 = p1[1];
    x2 = p2[0]; y2 = p2[1];

    float a = y2-y1;
    float b = -(x2-x1);
    float c = y1*(x2-x1) - x1*(y2-y1);

    res[0] = a; res[1] = b; res[2] = c;
}

float dist_point_to_line(float[2] p, float[3] eq)
{
    return abs(eq[0]*p[0] + eq[1]*p[1] + eq[2])/hypot(eq[0], eq[1]);
}

float signed_dist_point_to_line(float[2] p, float[3] eq)
{
    return (eq[0]*p[0] + eq[1]*p[1] + eq[2])/hypot(eq[0], eq[1]);
}

void intersection_by_equation(float[3] eq1, float[3] eq2, ref float[2] res)
{
    float a1, b1, c1;
    float a2, b2, c2;
    a1 = eq1[0]; b1 = eq1[1]; c1 = eq1[2];
    a2 = eq2[0]; b2 = eq2[1]; c2 = eq2[2];

    float d = a1*b2-a2*b1;
    float x = (b1*c2-b2*c1)/d;
    float y = (c1*a2-c2*a1)/d;

    res[0] = x;
    res[1] = y;
}

void intersection(float[2] p11, float[2] p12, float[2] p21, float[2] p22, ref float[2] res)
{
    float[3] eq1;
    float[3] eq2;
    line_equation(p11, p12, eq1);
    line_equation(p21, p22, eq2);

    intersection_by_equation(eq1, eq2, res);
}

void convert_between_rmb_xyy(Color *h6p, ColorType type, ErrCorrection correction)
{
    float xr, yr, xg, yg, xb, yb, xw, yw;
    xr = RMB_RGBSPACE.base.r.x; yr = RMB_RGBSPACE.base.r.y;
    xg = RMB_RGBSPACE.base.g.x; yg = RMB_RGBSPACE.base.g.y;
    xb = RMB_RGBSPACE.base.b.x; yb = RMB_RGBSPACE.base.b.y;
    xw = RMB_RGBSPACE.base.w.x; yw = RMB_RGBSPACE.base.w.y;

    assert(!h6p.channels[0].isNaN());
                
    if (type == ColorType.XYY)
    {
        h6p.space = &RMB_RGBSPACE;
        color_convert(h6p, &XYY_SPACE, correction);
    }       
            
    float x, y, yy;
    x = h6p.channels[0];
    y = h6p.channels[1];
    yy = h6p.channels[2];

    assert(!x.isNaN() && !y.isNaN() && !yy.isNaN(), "x="~x.text~", y="~y.text~" yy="~yy.text);

    float z = 1.0 - x - y;
    float xx, zz;
    xx = x*yy/y; zz = z*yy/y;

    float dx, dy;
    float dxr, dyr;
    float dxg, dyg;
    float dxb, dyb;

    dx = x - xw; dy = y - yw;
    dxr = xr - xw, dyr = yr - yw;
    dxg = xg - xw, dyg = yg - yw;
    dxb = xb - xw, dyb = yb - yw;

    if (hypot(dx, dy) < 1e-5 || yy < 1e-15)
    {
        if (type == ColorType.RMB)
        {
            if (yy < 1e-15)
            {
                h6p.channels[0] = 0.0;
                h6p.channels[1] = 0.0;
                h6p.channels[2] = 0.0;
            }
            else
            {
                h6p.channels[0] = xx;
                h6p.channels[1] = yy;
                h6p.channels[2] = zz;
                assert(!isNaN(h6p.channels[0]));

                h6p.space = &XYZ_SPACE;
                color_convert(h6p, &RMB_RGBSPACE, correction);
                assert(!isNaN(h6p.channels[0]));
            }
            return;
        }
        else
        {
            h6p.channels[0] = xw;
            h6p.channels[1] = yw;
            h6p.channels[2] = yy;
            assert(!isNaN(h6p.channels[0]));
            return;
        }
    }

    assert(!dy.isNaN() && !dx.isNaN(), "dx or dy is NaN");

    float angle = atan2(dy, dx);
    float angler = atan2(dyr, dxr);
    float angleg = atan2(dyg, dxg);
    float angleb = atan2(dyb, dxb);

    if (angle <= angler && angle >= angleb)
    {
        if (type == ColorType.RMB)
        {
            h6p.channels[0] = xx;
            h6p.channels[1] = yy;
            h6p.channels[2] = zz;
            assert(!isNaN(h6p.channels[0]));

            h6p.space = &XYZ_SPACE;
            color_convert(h6p, &RMB_RGBSPACE, correction);
            assert(!isNaN(h6p.channels[0]));
            return;
        }
        else
        {
            h6p.channels[0] = x;
            h6p.channels[1] = y;
            h6p.channels[2] = yy;
            assert(!isNaN(h6p.channels[0]));
            return;
        }
    }
    else
    {
        float xp, yp;
        float[2] pp;
        if (angle <= angleg && angle >= angler)
        {
            float[2] pw = [xw, yw];
            float[2] p = [x, y];
            float[2] pr = [xr, yr];
            float[2] pg = [xg, yg];
            intersection(pw, p, pr, pg, pp);
        }
        else
        {
            float[2] pw = [xw, yw];
            float[2] p = [x, y];
            float[2] pb = [xb, yb];
            float[2] pg = [xg, yg];
            intersection(pw, p, pb, pg, pp);
        }

        xp = pp[0]; yp = pp[1];
        assert(!isNaN(xp));
        assert(!isNaN(yp));

        float lambda;
        if (angle <= angleg && angle >= angler)
        {
            lambda = calc_lambda(angle);
        }
        else
        {
            if (angle < 0.0)
            {
                angle += 2.0*PI;
            }

            lambda = calc_lambda(angle);
        }

        assert(lambda > 0.0, "lambda is not positive on angle="~angle.text);
        assert(!isNaN(lambda));

        Color cl;
        xyy_color_matching(lambda, &cl);
        float xl, yl;
        xl = cl.channels[0];
        yl = cl.channels[1];

        float dxp, dyp;
        dxp = xp - xw; dyp = yp - yw;
        float dxl, dyl;
        dxl = xl - xw; dyl = yl - yw;

        float distp = hypot(dxp, dyp);
        float distl = hypot(dxl, dyl);
        assert(abs(distl) > 1e-15);

        if (type == ColorType.RMB)
        {
            dx = dx*distp/distl; dy = dy*distp/distl;

            float x1, y1, z1;
            x1 = xw + dx; y1 = yw + dy; z1 = 1.0 - x1 - y1;

            float xx1, zz1;
            xx1 = x1*yy/y1; zz1 = z1*yy/y1;
            assert(!isNaN(xx1));

            h6p.channels[0] = xx1;
            h6p.channels[1] = yy;
            h6p.channels[2] = zz1;
            assert(!isNaN(h6p.channels[0]));

            h6p.space = &XYZ_SPACE;
            color_convert(h6p, &RMB_RGBSPACE, correction);
            assert(!isNaN(h6p.channels[0]));
            return;
        }
        else
        {
            dx = dx*distl/distp; dy = dy*distl/distp;

            h6p.channels[0] = xw + dx;
            h6p.channels[1] = yw + dy;
            h6p.channels[2] = yy;
            assert(!isNaN(h6p.channels[0]));
            return;
        }
    }
}

float labf(float t)
{
    float delta = 6.0/29.0;

    if (t > pow(delta, 3.0))
    {
        return pow(t, 1.0/3.0);
    }
    else
    {
        return 1.0/3.0/delta/delta * t + 4.0/29.0;
    }
}

void color_convert(Color *h6p, const ColorSpace *to_space, ErrCorrection correction)
{
    assert(h6p.space !is null);
    if (*h6p.space == *to_space) return;

    assert(!isNaN(h6p.channels[0]));

    if (h6p.space.bounds) 
    {
        float[4] *itpn = &h6p.channels;
        const(Bounds) *n = &h6p.space.bounds;
        float i = (*itpn)[0] * ((*n)[1][0] - (*n)[0][0]) + (*n)[0][0];
        float t = (*itpn)[1] * ((*n)[1][1] - (*n)[0][1]) + (*n)[0][1];
        float p = (*itpn)[2] * ((*n)[1][2] - (*n)[0][2]) + (*n)[0][2];

        h6p.channels[0] = i;
        h6p.channels[1] = t;
        h6p.channels[2] = p;

        assert(!isNaN(h6p.channels[0]));
    }

    if (h6p.space.companding != CompandingType.NONE)
    {
        h6p.error |= prepare_positive(h6p.channels[0..3], correction);
        h6p.channels[0] = inv_companding(h6p.channels[0], h6p.space.companding);
        h6p.channels[1] = inv_companding(h6p.channels[1], h6p.space.companding);
        h6p.channels[2] = inv_companding(h6p.channels[2], h6p.space.companding);
        h6p.channels[3] = inv_companding(h6p.channels[3], h6p.space.alpha_companding);

        assert(!isNaN(h6p.channels[0]));
    }

    switch (h6p.space.type)
    {
        case ColorType.XYZ:
            break;

        case ColorType.RMB:
            if (to_space.type == ColorType.RMB)
            {
                goto companding;
            }

            convert_between_rmb_xyy(h6p, ColorType.XYY, correction);
            assert(!isNaN(h6p.channels[0]));
            // fallthrough
            goto case;

        case ColorType.XYY:
        {
            if (to_space.type == ColorType.XYY)
            {
                goto companding;
            }

            float[4] *xyy = &h6p.channels;
            float x = (*xyy)[0];
            float y = (*xyy)[1];
            float yy = (*xyy)[2];
            float z = 1.0 - x - y;

            h6p.channels[0] = x*yy/y;
            h6p.channels[1] = yy;
            h6p.channels[2] = z*yy/y;
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        case ColorType.YUV:
        {
            if ( to_space.type == ColorType.YUV &&
                    base_cmp(&h6p.space.base, &to_space.base) )
            {
                goto companding;
            }

            assert(h6p.space.rgb_matrices);
            const(float[9]) *m1 = &h6p.space.rgb_matrices.to_xyz;
            float[4] *yuv = &h6p.channels;

            float yr, yg, yb;
            yr = (*m1)[3]; yg = (*m1)[4]; yb = (*m1)[5];
            float umax = 0.5;
            float vmax = 0.5;

            float r = (*yuv)[0] + (*yuv)[2] * (1.0-yr) / vmax;
            float g = (*yuv)[0] - (*yuv)[1] * yb*(1.0-yb) / umax / yg -
                (*yuv)[2] * yr*(1.0-yr) / vmax / yg;
            float b = (*yuv)[0] + (*yuv)[1] * (1.0-yb) / umax;

            h6p.channels[0] = r;
            h6p.channels[1] = g;
            h6p.channels[2] = b;
            assert(!isNaN(h6p.channels[0]));
        }

            // fallthrough
            goto case;

        case ColorType.RGB:
        {
            if ( to_space.type == ColorType.RGB &&
                    base_cmp(&h6p.space.base, &to_space.base) )
            {
                goto companding;
            }

            assert(h6p.space.rgb_matrices !is null);
            const(float[9]) *m1 = &h6p.space.rgb_matrices.to_xyz;
            float[4] *rgbl = &h6p.channels;
            assert(!isNaN(h6p.channels[0]));
            assert(!isNaN(h6p.space.rgb_matrices.to_xyz[0]));

            float xr, xg, xb;
            float yr, yg, yb;
            float zr, zg, zb;

            xr = (*m1)[0], xg = (*m1)[1], xb = (*m1)[2];
            yr = (*m1)[3], yg = (*m1)[4], yb = (*m1)[5];
            zr = (*m1)[6], zg = (*m1)[7], zb = (*m1)[8];

            float x = xr * (*rgbl)[0] + xg * (*rgbl)[1] + xb * (*rgbl)[2];
            float y = yr * (*rgbl)[0] + yg * (*rgbl)[1] + yb * (*rgbl)[2];
            float z = zr * (*rgbl)[0] + zg * (*rgbl)[1] + zb * (*rgbl)[2];

            h6p.channels[0] = x;
            h6p.channels[1] = y;
            h6p.channels[2] = z;
            assert(!isNaN(h6p.channels[0]));

            break;
        }

        case ColorType.LAB:
        {
            if (to_space.type == ColorType.LAB)
            {
                goto companding;
            }

            float[4] *lab = &h6p.channels;
            float fy = ((*lab)[0] + 16.0)/116.0;
            float fx = fy + (*lab)[1]/500.0;
            float fz = fy - (*lab)[2]/200.0;

            float xn = D65_WHITE_COLOR.x;
            float yn = D65_WHITE_COLOR.y;
            float zn = 1.0 - xn - yn;

            float x = lab_c(fx, xn);
            float y = lab_c(fy, yn);
            float z = lab_c(fz, zn);

            h6p.channels[0] = x;
            h6p.channels[1] = y;
            h6p.channels[2] = z;
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        case ColorType.ITP:
            if (to_space.type == ColorType.ITP)
            {
                goto companding;
            }

            h6p.channels[1] = 2.0*h6p.channels[1];
            assert(!isNaN(h6p.channels[1]));

            // fallthrough
            goto case;

        case ColorType.ICTCP:
        {
            if (to_space.type == ColorType.ICTCP)
            {
                goto companding;
            }

            float[4] *ictcp = &h6p.channels;
            /*
             * Convert color from ICtCp color space to Lms
             * https://en.wikipedia.org/wiki/LMS_color_space and
             * https://en.wikipedia.org/wiki/ICtCp for details
             */
            float l = 1.0* (*ictcp)[0] + 0.01571858* (*ictcp)[1] + 0.209581068* (*ictcp)[2];
            float m = 1.0* (*ictcp)[0] - 0.01571858* (*ictcp)[1] - 0.209581068* (*ictcp)[2];
            float s = 1.0* (*ictcp)[0] + 1.02127108* (*ictcp)[1] - 0.605274491* (*ictcp)[2];
            h6p.channels[0] = l;
            h6p.channels[1] = m;
            h6p.channels[2] = s;
            assert(!isNaN(h6p.channels[0]));

            h6p.error |= prepare_positive(h6p.channels[0..3], correction);
            h6p.channels[0] = inv_companding(h6p.channels[0], CompandingType.HLG);
            h6p.channels[1] = inv_companding(h6p.channels[1], CompandingType.HLG);
            h6p.channels[2] = inv_companding(h6p.channels[2], CompandingType.HLG);
            assert(!isNaN(h6p.channels[0]));
        }
            // fallthrough
            goto case;

        case ColorType.LMS:
        {
            if (to_space.type == ColorType.LMS)
            {
                goto companding;
            }

            float[4] *lms = &h6p.channels;
            float x = 1.73126* (*lms)[0] - 1.05126 * (*lms)[1] + 0.20467 * (*lms)[2];
            float y = 0.33621* (*lms)[0] + 0.65399 * (*lms)[1] - 0.00296 * (*lms)[2];
            float z =                                            1.08909 * (*lms)[2];

            h6p.channels[0] = x;
            h6p.channels[1] = y;
            h6p.channels[2] = z;
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        default:
            assert(0);
    }

    switch (to_space.type)
    {
        case ColorType.XYZ:
            break;

        case ColorType.XYY:
        case ColorType.RMB:
        {
            float[4] *xyz = &h6p.channels;
            float x, y, z;
            x = (*xyz)[0]; y = (*xyz)[1]; z = (*xyz)[2];
            float sum = x + y + z;

            if (abs(sum) < 1e-5)
            {
                float xw = D65_WHITE_COLOR.x;
                float yw = D65_WHITE_COLOR.y;
                h6p.channels[0] = xw;
                h6p.channels[1] = yw;
                h6p.channels[2] = y;
                assert(!isNaN(h6p.channels[0]));
            }
            else
            {
                h6p.channels[0] = x/sum;
                h6p.channels[1] = y/sum;
                h6p.channels[2] = y;
                assert(!isNaN(h6p.channels[0]));
            }

            if (to_space.type == ColorType.XYY)
            {
                goto companding;
            }

            convert_between_rmb_xyy(h6p, ColorType.RMB, correction);
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        case ColorType.RGB:
        case ColorType.YUV:
        {
            assert(to_space.rgb_matrices);
            const(float[9]) *m2 = &to_space.rgb_matrices.from_xyz;
            float[4] *xyz = &h6p.channels;

            float rx, ry, rz;
            float gx, gy, gz;
            float bx, by, bz;

            rx = (*m2)[0]; ry = (*m2)[1]; rz = (*m2)[2];
            gx = (*m2)[3]; gy = (*m2)[4]; gz = (*m2)[5];
            bx = (*m2)[6]; by = (*m2)[7]; bz = (*m2)[8];

            float r = rx * (*xyz)[0] + ry * (*xyz)[1] + rz * (*xyz)[2];
            float g = gx * (*xyz)[0] + gy * (*xyz)[1] + gz * (*xyz)[2];
            float b = bx * (*xyz)[0] + by * (*xyz)[1] + bz * (*xyz)[2];
            //printf("%.3f %.3f %.3f\n", rx, gy, bz);

            assert(!isNaN((*xyz)[0]));
            assert(!isNaN(r));

            h6p.channels[0] = r;
            h6p.channels[1] = g;
            h6p.channels[2] = b;
            assert(!isNaN(h6p.channels[0]));

            if (to_space.type == ColorType.RGB)
            {
                goto companding;
            }

            const(float[9]) *m1 = &to_space.rgb_matrices.to_xyz;
            float[4] *rgbl = &h6p.channels;

            float yr, yg, yb;
            yr = (*m1)[3], yg = (*m1)[4], yb = (*m1)[5];

            float umax = 0.5;
            float vmax = 0.5;

            float y = yr * (*rgbl)[0] + yg * (*rgbl)[1] + yb * (*rgbl)[2];
            float u = umax*((*rgbl)[2] - y)/(1.0 - yb);
            float v = vmax*((*rgbl)[0] - y)/(1.0 - yr);

            h6p.channels[0] = y;
            h6p.channels[1] = u;
            h6p.channels[2] = v;
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        case ColorType.LAB:
        {
            const(float[4]) *xyz = &h6p.channels;
            float xn = D65_WHITE_COLOR.x;
            float yn = D65_WHITE_COLOR.y;
            float zn = 1.0 - xn - yn;

            float l = 116.0 * labf((*xyz)[1]/yn) - 16.0;
            float a = 500.0 * (labf((*xyz)[0]/xn) - labf(((*xyz)[1])/yn));
            float b = 200.0 * (labf((*xyz)[1]/yn) - labf(((*xyz)[2])/zn));

            h6p.channels[0] = l;
            h6p.channels[1] = a;
            h6p.channels[2] = b;
            assert(!isNaN(h6p.channels[0]));
            break;
        }

        /*
         * https://en.wikipedia.org/wiki/LMS_color_space for details
         * https://en.wikipedia.org/wiki/ICtCp for details
         */
        case ColorType.LMS:
        case ColorType.ICTCP:
        case ColorType.ITP:
        {
            float[4] *xyz = &h6p.channels;
            // D65 coefs
            float l =  0.4402* (*xyz)[0] + 0.7076* (*xyz)[1] - 0.0808* (*xyz)[2];
            float m = -0.2263* (*xyz)[0] + 1.1653* (*xyz)[1] + 0.0457* (*xyz)[2];
            float s =                                          0.9182* (*xyz)[2];

            h6p.channels[0] = l;
            h6p.channels[1] = m;
            h6p.channels[2] = s;

            if (to_space.type == ColorType.LMS)
            {
                goto companding;
            }

            h6p.error |= prepare_positive(h6p.channels[0..3], correction);
            h6p.channels[0] = companding(h6p.channels[0], CompandingType.HLG);
            h6p.channels[1] = companding(h6p.channels[1], CompandingType.HLG);
            h6p.channels[2] = companding(h6p.channels[2], CompandingType.HLG);

            float[4] *lms_hlg = &h6p.channels;
            float  i = (2048.0* (*lms_hlg)[0] + 2048.0* (*lms_hlg)[1]                   )/4096.0;
            float ct = (3625.0* (*lms_hlg)[0] - 7465.0* (*lms_hlg)[1] + 3840.0* (*lms_hlg)[2])/4096.0;
            float cp = (9500.0* (*lms_hlg)[0] - 9212.0* (*lms_hlg)[1] - 288.0* (*lms_hlg)[2] )/4096.0;
            h6p.channels[0] = i;
            h6p.channels[1] = ct;
            h6p.channels[2] = cp;
            assert(!isNaN(h6p.channels[1]));

            if (to_space.type == ColorType.ICTCP)
            {
                goto companding;
            }

            h6p.channels[1] = 0.5*h6p.channels[1];
            assert(!isNaN(h6p.channels[1]));

            break;
        }

        default:
            assert(0);
    }

companding:
    if (to_space.companding != CompandingType.NONE)
    {
        h6p.error |= prepare_positive(h6p.channels[0..3], correction);
        h6p.channels[0] = companding(h6p.channels[0], to_space.companding);
        h6p.channels[1] = companding(h6p.channels[1], to_space.companding);
        h6p.channels[2] = companding(h6p.channels[2], to_space.companding);
        h6p.channels[3] = companding(h6p.channels[3], to_space.alpha_companding);
        assert(!isNaN(h6p.channels[0]));
    }

    if (to_space.bounds)
    {
        const(Bounds) *n = &to_space.bounds;
        float[4] *itp = &h6p.channels;
        float i = ((*itp)[0] - (*n)[0][0]) / ((*n)[1][0] - (*n)[0][0]);
        float t = ((*itp)[1] - (*n)[0][1]) / ((*n)[1][1] - (*n)[0][1]);
        float p = ((*itp)[2] - (*n)[0][2]) / ((*n)[1][2] - (*n)[0][2]);

        h6p.channels[0] = i;
        h6p.channels[1] = t;
        h6p.channels[2] = p;
        assert(!isNaN(h6p.channels[0]));
    }

    h6p.space = to_space;
}

/*
 * Color difference in ITP color space
 * https://en.wikipedia.org/wiki/Color_difference#Rec._ITU-R_BT.2124_or_%CE%94EITP for details
 */
float color_dist(Color *h6p, Color *other, ErrCorrection correction)
{
    assert(h6p !is null);
    assert(other !is null);

    Color a, b;
    a = *h6p;
    b = *other;

    color_convert(&a, &ITP_SPACE, correction);
    color_convert(&b, &ITP_SPACE, correction);
    float dist = 720*dist3(a.channels[0..3], b.channels[0..3]);
    return dist;
}

Color *color_copy(Color *h6p)
{
    Color *copy = new Color;
    assert(copy !is null);

    *copy = *h6p;
    return copy;
}

void color_mix(Mixer *mixer, Color *h6p, ErrCorrection correction)
{
    if (mixer.color is null)
    {
        mixer.color = color_copy(h6p);
        color_convert(mixer.color, &XYZ_SPACE, correction);
        mixer.num = 1;
        return;
    }

    Color a;
    a = *h6p;
    color_convert(&a, &XYZ_SPACE, correction);

    mixer.color.channels[0] += a.channels[0];
    mixer.color.channels[1] += a.channels[1];
    mixer.color.channels[2] += a.channels[2];
    mixer.color.channels[3] += a.channels[3];

    mixer.num++;
}

void color_mix_finish(Mixer *mixer)
{
    if (mixer.num == 0) return;
    mixer.color.channels[0] /= mixer.num;
    mixer.color.channels[1] /= mixer.num;
    mixer.color.channels[2] /= mixer.num;
    mixer.color.channels[3] /= mixer.num;
}

