#version 120
uniform sampler2D iChannel0;

uniform float shiftFactor;

vec3 hueShift(vec3 col, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return vec3(col * cosAngle + cross(k, col) * sin(hue) + k * dot(k, col) * (1.0 - cosAngle));
}

void main()
{
	vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);

	vec3 cs = hueShift(c.rgb,shiftFactor);
	
	gl_FragColor = vec4(cs,c.a);
}