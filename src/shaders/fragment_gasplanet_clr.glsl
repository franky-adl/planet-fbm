vec2 uv = v_Uv;
vec2 st = vec2(uv.x * 2., uv.y * 1.) * scale + vec2(shift);
float time = u_time * timeSpeed;

// parameters worth tweaking for the generator
float baseSharpness = 4.;
float sharpnessFluctuator = 1.5;

// fbm noise mapping - 0:value, 1:simplex, 2:voronoi, 3:darkSimplex, 4:perlin
// [Warper] used to warp the waver pattern instead of the final pattern
float warper = fbm( vec2(uv.x * 6., uv.y * 8.) * warperScale , 3 );
// [Waver] fluctuate y value acoording to both x and y, making the bands wavier 
// further applying a cos at the end so the waves are only applied to certain y-sections
float waver = cnoise(st * waverScale + warper * warperFactor + time * 0.5) * waverFactor * (cos(uv.y * 3. * PI + waverShift) + 1.);
float tmpY = st.y * 6. + waver;
// [Pulser] fluctuate the slope of y value, making the bands have a bit of varying widths
tmpY += pulserAmp * (sin(tmpY + pulserOffset) + sin(tmpY*1.3 + pulserOffset));
// [Base Pattern] finally get 1D value noise over the tempered y value, and warp it with the warper
// [Sharpness Fluctuator] 2nd parameter is for the variator in the steepstep function, 
// so as to create varying steepness of smooth transitions between bands
float warped_l = noise_1d( vec2(st.x, tmpY) + vec2(time, 0.), baseSharpness + sharpnessFluctuator * (sin(st.y * 12.) + sin(st.y * 12.*1.3)) );

// Nice and tested color themes:
// 1. monochromatic, and near saturation, and varying degrees of Luminosity
// 2. analogous, and near saturation, and varying degrees of Luminosity
// 3. reverse monochromatic, reversing order of luminosity from 1
// 4. reverse analogous, reversing order of luminosity from 2
// 5. near monochromatic, mid saturation(exclude brightest color), decreasing lightness from L2 to D1, pretty nice for hue at 0.1
// 6. near monochromatic, mid saturation, decreasing lightness from L2 to D2, except darkest color becomes brightest
// 7. near monochromatic, D1 has -0.2 hue, 0.9 S and 0.7 L, others have random saturation, decreasing lightness from L2 to D2
// 8. pick D1 as the most vibrant (hue - .2, 0.9, 0.5), others roughly same hue, low saturation, decreasing lightness from L2 to D2
vec3 colorD1 = vec3(0.);
vec3 colorD2 = vec3(0.);
vec3 colorL1 = vec3(0.);
vec3 colorL2 = vec3(0.);
if (colorScheme == 1) { // monochromatic
    // dark colors mix in a darker color range
    colorD1 = hsl2rgb(vec3(hue - 0.05, 0.65, 0.4));
    colorD2 = hsl2rgb(vec3(hue, 0.6, 0.54));
    // light colors mix in a lighter range
    colorL1 = hsl2rgb(vec3(hue + 0.05, 0.5, 0.62));
    colorL2 = hsl2rgb(vec3(hue + 0.05, 1.0, 0.9));
} else if (colorScheme == 2) { // analogous
    colorD1 = hsl2rgb(vec3(hue - 0.1, 0.8, 0.2));
    colorD2 = hsl2rgb(vec3(hue, 0.7, 0.5));
    colorL1 = hsl2rgb(vec3(hue + 0.05, 0.5, 0.7));
    colorL2 = hsl2rgb(vec3(hue + 0.1, 0.7, 0.9));
} else if (colorScheme == 3) { // reverse monochromatic
    colorD1 = hsl2rgb(vec3(hue + 0.05, 1.0, 0.9));
    colorD2 = hsl2rgb(vec3(hue + 0.05, 0.5, 0.62));
    colorL1 = hsl2rgb(vec3(hue, 0.6, 0.54));
    colorL2 = hsl2rgb(vec3(hue - 0.05, 0.65, 0.4));
} else if (colorScheme == 4) { // reverse analogous
    colorD1 = hsl2rgb(vec3(hue + 0.1, 0.7, 0.9));
    colorD2 = hsl2rgb(vec3(hue + 0.05, 0.5, 0.7));
    colorL1 = hsl2rgb(vec3(hue, 0.7, 0.5));
    colorL2 = hsl2rgb(vec3(hue - 0.1, 0.8, 0.2));
}

vec3 fC = vec3(0.);

float midWidth = 0.1;
float switchPt = 0.2;
float lB = switchPt - midWidth / 2.;
float hB = switchPt + midWidth / 2.;
if (warped_l < lB) {
    fC = mix(colorD1, colorD2, warped_l / lB);
} else if (warped_l >= lB && warped_l <= hB) {
    fC = mix(colorD2, colorL1, (warped_l - lB) / midWidth);
} else {
    fC = mix(colorL1, colorL2, (warped_l - hB)/(1. - hB));
}

// Adding a small amount of atmospheric fresnel effect for extra realism
// fine tune the first constant below for stronger or weaker effect
float intensity = 1.3 - dot( v_Normal, vec3( 0.0, 0.0, 1.0 ) );
vec3 atmosphere = colorL1 * pow(intensity, 5.0);

fC += atmosphere;

diffuseColor.rgb = fC;