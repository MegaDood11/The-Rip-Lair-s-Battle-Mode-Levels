// Sorta just the body shader but made to work for one big glDraw call

#version 120
uniform sampler2D iChannel0;

uniform float timer;
uniform float frames;
uniform float frameDelay;

uniform float pixelSize;

uniform vec2 screenSize;
uniform vec2 bodyTextureSize;

uniform vec2 perlinOffset;
uniform sampler2D perlinTexture;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	vec2 screenXY = floor(gl_FragCoord.xy/pixelSize)*pixelSize;

	//vec2 perlinXY = mod((screenXY - perlinOffset)/bodyTextureSize,1.0);
	vec2 perlinXY = mod((screenXY - perlinOffset)/screenSize*3.0,1.0);
	float delay = texture2D(perlinTexture,perlinXY).r * frames * frameDelay;

	float frame = mod(floor((timer - delay)/frameDelay),frames);

	vec2 finalXY = vec2(mod(xy.x,1.0),mod(xy.y,1.0/frames) + frame/frames);

	vec4 c = texture2D(iChannel0,finalXY);

	//c = texture2D(perlinTexture,perlinXY);
	
	gl_FragColor = c*gl_Color;
}