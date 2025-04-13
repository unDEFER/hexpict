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
module hexpict.colors;

import hexpict.color;

// Standard illuminants according https://en.wikipedia.org/wiki/Standard_illuminant
immutable XyType A_WHITE_COLOR = XyType(0.44757, 0.40745);
immutable XyType B_WHITE_COLOR = XyType(0.34842, 0.35161);
immutable XyType C_WHITE_COLOR = XyType(0.31006, 0.31616);
immutable XyType D50_WHITE_COLOR = XyType(0.34567, 0.35850);
immutable XyType D55_WHITE_COLOR = XyType(0.33242, 0.34743);
immutable XyType D65_WHITE_COLOR = XyType(0.31271, 0.32902);
immutable XyType D75_WHITE_COLOR = XyType(0.29902, 0.31485);
immutable XyType D93_WHITE_COLOR = XyType(0.28315, 0.29711);
immutable XyType E_WHITE_COLOR = XyType(0.33333, 0.33333);
immutable XyType F1_WHITE_COLOR = XyType(0.31310, 0.33727);
immutable XyType F2_WHITE_COLOR = XyType(0.37208, 0.37529);
immutable XyType F3_WHITE_COLOR = XyType(0.40910, 0.39430);
immutable XyType F4_WHITE_COLOR = XyType(0.44018, 0.40329);
immutable XyType F5_WHITE_COLOR = XyType(0.31379, 0.34531);
immutable XyType F6_WHITE_COLOR = XyType(0.37790, 0.38835);
immutable XyType F7_WHITE_COLOR = XyType(0.31292, 0.32933);
immutable XyType F8_WHITE_COLOR = XyType(0.34588, 0.35875);
immutable XyType F9_WHITE_COLOR = XyType(0.37417, 0.37281);
immutable XyType F10_WHITE_COLOR = XyType(0.34609, 0.35986);
immutable XyType F11_WHITE_COLOR = XyType(0.38052, 0.37713);
immutable XyType F12_WHITE_COLOR = XyType(0.43695, 0.40441);
immutable XyType LED_B1_WHITE_COLOR = XyType(0.4560, 0.4078);
immutable XyType LED_B2_WHITE_COLOR = XyType(0.4357, 0.4012);
immutable XyType LED_B3_WHITE_COLOR = XyType(0.3756, 0.3723);
immutable XyType LED_B4_WHITE_COLOR = XyType(0.3422, 0.3502);
immutable XyType LED_B5_WHITE_COLOR = XyType(0.3118, 0.3236);
immutable XyType LED_BH1_WHITE_COLOR = XyType(0.4474, 0.4066);
immutable XyType LED_RGB1_WHITE_COLOR = XyType(0.4557, 0.4211);
immutable XyType LED_V1_WHITE_COLOR = XyType(0.4560, 0.4548);
immutable XyType LED_V2_WHITE_COLOR = XyType(0.3781, 0.3775);

// RGB Base colors according http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
immutable ColorSpace ADOBE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2100, 0.7100), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace APPLE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6250, 0.3400), XyType(0.2800, 0.5950), XyType(0.1550, 0.0700)), null, null);

immutable ColorSpace BEST_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7347, 0.2653), XyType(0.2150, 0.7750), XyType(0.1300, 0.0350)), null, null);

immutable ColorSpace BETA_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6888, 0.3112), XyType(0.1986, 0.7551), XyType(0.1265, 0.0352)), null, null);

immutable ColorSpace BRUCE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2800, 0.6500), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace CIE_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.33333, 0.33333), XyType(0.7350, 0.2650), XyType(0.2740, 0.7170), XyType(0.1670, 0.0090)), null, null);

immutable ColorSpace COLORMATCH_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6300, 0.3400), XyType(0.2950, 0.6050), XyType(0.1500, 0.0750)), null, null);

immutable ColorSpace DON_RGB_4_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6960, 0.3000), XyType(0.2150, 0.7650), XyType(0.1300, 0.0350)), null, null);

immutable ColorSpace ECI_RGB_V2_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.L, CompandingType.NONE,
    CompandingType.L, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6700, 0.3300), XyType(0.2100, 0.7100), XyType(0.1400, 0.0800)), null, null);

immutable ColorSpace EKTA_SPACE_PS5_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.6950, 0.3050), XyType(0.2600, 0.7000), XyType(0.1100, 0.0050)), null, null);

immutable ColorSpace NTSC_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31006, 0.31616), XyType(0.6700, 0.3300), XyType(0.2100, 0.7100), XyType(0.1400, 0.0800)), null, null);

immutable ColorSpace PAL_SECAM_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.2900, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace PROPHOTO_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    CompandingType.GAMMA_1_8, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7347, 0.2653), XyType(0.1596, 0.8404), XyType(0.0366, 0.0001)), null, null);

immutable ColorSpace SMPTE_C_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6300, 0.3400), XyType(0.3100, 0.5950), XyType(0.1550, 0.0700)), null, null);

immutable ColorSpace SRGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace WIDE_GAMUT_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.34567, 0.35850), XyType(0.7350, 0.2650), XyType(0.1150, 0.8260), XyType(0.1570, 0.0180)), null, null);

// Rec. 2020
immutable ColorSpace REC2020_RGB_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    CompandingType.GAMMA_2_2, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.7080, 0.2920), XyType(0.1700, 0.7970), XyType(0.1310, 0.0460)), null, null);

// https://en.wikipedia.org/wiki/DCI-P3
immutable XyType K6000_WHITE_COLOR = XyType(0.32168, 0.33767);
immutable XyType K6300_WHITE_COLOR = XyType(0.314, 0.351);

immutable ColorSpace DCI_P3_DISPLAY_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

immutable ColorSpace DCI_P3_THEATER_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.314, 0.351), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

immutable ColorSpace DCI_P3_ACES_CINEMA_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.32168, 0.33767), XyType(0.680, 0.320), XyType(0.265, 0.690), XyType(0.150, 0.060)), null, null);

immutable ColorSpace DCI_P3_PLUS_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    CompandingType.GAMMA_2_6, CompandingType.NONE,
    RgbBaseColors(XyType(0.314, 0.351), XyType(0.740, 0.270), XyType(0.220, 0.780), XyType(0.090, -0.090)), null, null);

immutable ColorSpace DCI_P3_CINEMA_GAMUT_SPACE = ColorSpace(ColorType.RGB,
    CompandingType.SRGB, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.740, 0.270), XyType(0.170, 1.140), XyType(0.080, -0.100)), null, null);

immutable ColorSpace RMB_SPACE = ColorSpace(ColorType.RMB,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace XYZ_SPACE = ColorSpace(ColorType.XYZ,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace XYY_SPACE = ColorSpace(ColorType.XYY,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace YUV_SPACE = ColorSpace(ColorType.YUV,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace LAB_SPACE = ColorSpace(ColorType.LAB,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace LMS_SPACE = ColorSpace(ColorType.LMS,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace ICTCP_SPACE = ColorSpace(ColorType.ICTCP,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);

immutable ColorSpace ITP_SPACE = ColorSpace(ColorType.ITP,
    CompandingType.NONE, CompandingType.NONE,
    CompandingType.SRGB, CompandingType.NONE,
    RgbBaseColors(XyType(0.31271, 0.32902), XyType(0.6400, 0.3300), XyType(0.3000, 0.6000), XyType(0.1500, 0.0600)), null, null);
