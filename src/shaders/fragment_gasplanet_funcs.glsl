vec4 mod289(vec4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x)
{
  return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise, should return [-1..1]
float cnoise(vec2 P)
{
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
  vec4 gy = abs(gx) - 0.5 ;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;  
  g01 *= norm.y;  
  g10 *= norm.z;  
  g11 *= norm.w;  

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));

  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

// Classic Perlin noise, periodic variant, should return [-1..1]
float pnoise(vec2 P, vec2 rep)
{
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, rep.xyxy); // To create noise with explicit period
  Pi = mod289(Pi);        // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
  vec4 gy = abs(gx) - 0.5 ;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;  
  g01 *= norm.y;  
  g10 *= norm.z;  
  g11 *= norm.w;  

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));

  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

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

float fbm ( in vec2 _st, int octaves ) {
  // v is the final result
  float v = 0.0;
  // a means amplitude of the octave
  float a = 0.5;
  float rot_angle = 1.0;
  mat2 rot = mat2(cos(rot_angle), sin(rot_angle),
                  -sin(rot_angle), cos(rot_angle));
  for (int i = 0; i < octaves; ++i) {
    // adds amplituded noise to the final accumulated result v
    v += a * cnoise(_st);
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
    float sn = fbm(st * 4., 3) * 0.2;

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