// reference from https://youtu.be/vM8M4QloVL0?si=CKD5ELVrRm3GjDnN
varying vec3 vNormal;
varying vec3 eyeVector;
uniform float hue;

vec3 hsl2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

void main() {
    // Starting from the rim to the center at the back, dotP would increase from 0 to 1
    float dotP = dot( vNormal, eyeVector );
    // This factor is to create the effect of a realistic thickening of the atmosphere coloring
    float factor = pow(dotP, 4.1) * 9.5;

    vec3 atmColor = hsl2rgb(vec3(hue, 0.8, 0.7));
    // Adding in a bit of dotP to the color to make it whiter while the color intensifies
    atmColor += vec3(dotP/4.5, dotP/4.5, 0.0);

    // use atmOpacity to control the overall intensity of the atmospheric color
    gl_FragColor = vec4(atmColor, 0.7) * factor;
}