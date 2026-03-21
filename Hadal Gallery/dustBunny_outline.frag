// Apply an outline to all the body sprites.

#version 120
uniform sampler2D iChannel0;

uniform vec2 scrollOffset;
uniform	vec2 pixelSize;

uniform vec2 bufferSize;

uniform sampler2D outlineColors;
uniform sampler2D perlinTexture;

#define OUTLINE_THICKNESS 0
#define PIXEL_SIZE 1


#include "shaders/logic.glsl"

float findNewOutlineOpacity(float outlineOpacity, vec2 xy, vec2 dir)
{
	for (float i = 1.0; i <= OUTLINE_THICKNESS/PIXEL_SIZE; i++)
	{
		vec2 checkXY = xy + (dir*PIXEL_SIZE*i)/bufferSize;
		vec4 checkC = texture2D(iChannel0, checkXY);

		outlineOpacity = max(outlineOpacity,checkC.a);
	}

	return outlineOpacity;
}

void main()
{
	vec2 xy = gl_TexCoord[0].xy;

	// Colour on the original texture
	vec4 c = texture2D(iChannel0, xy);

	#if OUTLINE_THICKNESS > 0.0 // no need to run all of this is it's 0
		// Find color to use for the outline, using the perlin and outline color textures
		vec2 perlinXY = mod(xy - scrollOffset,1.0);
		float perlinValue = texture2D(perlinTexture,perlinXY).r;

		vec4 outlineC = texture2D(outlineColors, vec2(perlinValue,0.0));

		// Find if there should be an outline here
		float outlineOpacity = 0.0;

		outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(0.0,-1.0)); // up
		outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(1.0,0.0));  // right
		outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(0.0,1.0));  // down
		outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(-1.0,0.0)); // left

		#if OUTLINE_THICKNESS > 2.0 // only really necessary for larger thickness values
			// Check for diagonals
			outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(0.5,-0.5));  // up right
			outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(-0.5,-0.5)); // up left
			outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(0.5,0.5));   // down right
			outlineOpacity = findNewOutlineOpacity(outlineOpacity,xy,vec2(-0.5,0.5));  // down left
		#endif

		// If there's already a pixel here, there should be no outline
		outlineOpacity *= le(c.a,0.0);


		// Combine the existing color with the outline
		c = mix(c,outlineC,outlineOpacity);
		
		//c = vec4(outlineOpacity,outlineOpacity,outlineOpacity,1.0);
	#endif
	
	gl_FragColor = c*gl_Color;
}