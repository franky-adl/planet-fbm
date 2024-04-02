#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926538

#pragma glslify: snoise = require('./simplex2d.glsl')
#pragma glslify: noise = require('./value2d.glsl')
#pragma glslify: voronoi = require('./voronoi2d.glsl')
#pragma glslify: cnoise = require('./perlin2d.glsl')

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform float scale;
uniform float shift;
uniform float waverScale;
uniform float waverFactor;
uniform float waverShift;
uniform float warperScale;
uniform float warperFactor;
uniform float pulserAmp;
uniform float pulserOffset;
uniform float hue;
uniform int colorScheme;
uniform float timeSpeed;
varying vec2 vUv;
varying vec3 vNormal;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float random1D ( float x ) {
  return fract(sin(x)*5000.);
}

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

// https://thebookofshaders.com/edit.php#05/cubicpulse.frag , www.iquilezles.org/www/articles/functions/functions.htm
float cubicPulse( float c, float w, float x ){
  x = abs(x - c);
  if( x>w ) return 0.0;
  x /= w;
  return 1.0 - x*x*(3.0-2.0*x);
}

// https://www.shadertoy.com/view/ltjcWW
// modified from gain1 function
float steepstep(float x, float k)
{
    float s = sign(x-0.5);
    float o = (1.0+s)/2.0;
    return o - 0.5*s*pow(2.0*(o-s*x),k);
}

float fbm ( in vec2 _st, int noiseFlag, int octaves ) {
  // v is the final result
  float v = 0.0;
  // a means amplitude of the octave
  float a = 0.5;
  float rot_angle = 1.0;
  mat2 rot = mat2(cos(rot_angle), sin(rot_angle),
                  -sin(rot_angle), cos(rot_angle));
  for (int i = 0; i < octaves; ++i) {
    // adds amplituded noise to the final accumulated result v
    if (noiseFlag == 0) {
      v += a * noise(_st);
    } else if (noiseFlag == 1) {
      v += a * (snoise(_st) * 0.5 + 0.5);
    } else if (noiseFlag == 2) {
      v += a * voronoi(_st);
    } else if (noiseFlag == 3) {
      v += a * snoise(_st);
    } else if (noiseFlag == 4) {
      v += a * cnoise(_st);
    }
    // Rotate to reduce axial bias,
    // up frequency 2 times
    // (optional) shift the coordinates with a vec2 increment
    _st = rot * _st * 2.0;
    // half the amplitude for next round
    a *= 0.5;
  }
  return v;
}

// 1D value noise, based on Morgan McGuire @morgan3d
// should be returning range of 0 to 1
// https://www.shadertoy.com/view/4dS3Wd
float noise_1d (in vec2 st, float variator) {
    float i = floor(st.y);
    float f = fract(st.y);

    // upper and lower bounds
    float a = random1D(i);
    float b = random1D(i + 1.0);
    // an intermediate bound for making that sharp band
    float c = random1D(i + 0.5);

    // sub-noise
    float sn = fbm(st * 4., 4, 3) * 0.2;

    // creating sharp bands in the noise pattern
    // f3 is basically shaped like a circus tent
    // interpolate from a to c using left side of the circus-tent function
    // then interpolate from c to b using right side of the circus-tent function
    float f1 = sign(f - 0.5);
    float f2 = (f1 + 1.) / 2.;
    float f3 = pow(2. * (f2 - f1 * f), variator);
    float fC = 0.;
    if (f < 0.5) {
      fC = mix(a, c, f3);
    } else {
      fC = mix(c, b, 1.-f3);
    }
    return mix(fC, sn, 0.3);
}

void main() {
  vec2 st = vec2(vUv.x * 2., vUv.y * 1.) * scale + vec2(shift);
  float time = u_time * timeSpeed;

  // parameters worth tweaking for the generator
  float baseSharpness = 4.;
  float sharpnessFluctuator = 1.5;

  // fbm noise mapping - 0:value, 1:simplex, 2:voronoi, 3:darkSimplex, 4:perlin
  // [Warper] used to warp the waver pattern instead of the final pattern
  float warper = fbm( vec2(vUv.x * 6., vUv.y * 8.) * warperScale , 4, 3 );
  // [Waver] fluctuate y value acoording to both x and y, making the bands wavier 
  // further applying a cos at the end so the waves are only applied to certain y-sections
  float waver = cnoise(st * waverScale + warper * warperFactor + time * 0.5) * waverFactor * (cos(vUv.y * 3. * PI + waverShift) + 1.);
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

  gl_FragColor = vec4(fC, 1.0);

  // Adding a small amount of atmospheric fresnel effect for extra realism
  // fine tune the first constant below for stronger or weaker effect
  float intensity = 1.3 - dot( vNormal, vec3( 0.0, 0.0, 1.0 ) );
  vec3 atmosphere = colorL1 * pow(intensity, 5.0);

  gl_FragColor.rgb += atmosphere;
}