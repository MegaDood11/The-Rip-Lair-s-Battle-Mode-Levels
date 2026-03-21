// Changes between each frame very slowly, but each pixel is slightly delayed.

#version 120
uniform sampler2D iChannel0;

uniform float timer;
uniform float frames;
uniform float frameDelay;

uniform vec2 perlinOffset;

uniform vec2 pixelSize;

uniform sampler2D perlinTexture;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	vec2 frameXY = floor(xy/pixelSize)*pixelSize*vec2(1.0,frames);

	vec2 perlinXY = mod(frameXY - perlinOffset,1.0);
	float delay = texture2D(perlinTexture, perlinXY).r * frames * frameDelay;

	float frame = mod(floor((timer - delay)/frameDelay),frames);

	vec2 finalXY = vec2(xy.x,xy.y + frame/frames);

	vec4 c = texture2D(iChannel0, finalXY);

	//c = texture2D(perlinTexture, perlinXY);
	
	gl_FragColor = c*gl_Color;
}