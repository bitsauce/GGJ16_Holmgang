//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D texture_sf_water_reflection;
uniform sampler2D s_normalMap;

uniform float time;
uniform float reflection_y;

float amplitude, total, cell_pos_1d, cell_pos_1d_floored, overhanginess;
vec2 cell_pos_2d, cell_pos_2d_floored;
vec3 cell_pos_3d, cell_pos_3d_floored;

float random_2d(vec2 pos) {
    return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453) * 2.0 - 1.0;
}

float random_3d(vec3 pos) {
    return fract(sin(dot(pos, vec3(12.9898, 78.233, 52.4287))) * 43758.5453) * 2.0 - 1.0;
}

float fractal_noise_2d(int octaves, vec2 pos, vec2 scale) {
    total = 0.0; amplitude = 1.0; cell_pos_2d = pos * scale;
    for (int i = 0; i < octaves; ++i) {
        cell_pos_2d_floored = floor(cell_pos_2d);
        total += mix(
            mix(random_2d(cell_pos_2d_floored), random_2d(cell_pos_2d_floored + vec2(1.0, 0.0)), smoothstep(0.0, 1.0, cell_pos_2d.x - cell_pos_2d_floored.x)),
            mix(random_2d(cell_pos_2d_floored + vec2(0.0, 1.0)), random_2d(cell_pos_2d_floored + vec2(1.0, 1.0)), smoothstep(0.0, 1.0, cell_pos_2d.x - cell_pos_2d_floored.x)),
            smoothstep(0.0, 1.0, cell_pos_2d.y - cell_pos_2d_floored.y)
        ) * amplitude;
        cell_pos_2d *= 2.0;
        amplitude *= 0.65;
    }
    return total;
}

float fractal_noise_3d(int octaves, vec3 pos, vec3 scale) {
    total = 0.0; amplitude = 1.0; cell_pos_3d = pos * scale;
    for (int i = 0; i < octaves; ++i) {    
        cell_pos_3d_floored = floor(cell_pos_3d);
        total += mix(
            mix(
                mix(random_3d(cell_pos_3d_floored), random_3d(cell_pos_3d_floored + vec3(1.0, 0.0, 0.0)), cell_pos_3d.x - cell_pos_3d_floored.x),
                mix(random_3d(cell_pos_3d_floored + vec3(0.0, 1.0, 0.0)), random_3d(cell_pos_3d_floored + vec3(1.0, 1.0, 0.0)), cell_pos_3d.x - cell_pos_3d_floored.x),
                smoothstep(0.0, 1.0, cell_pos_3d.y - cell_pos_3d_floored.y)
            ),
            mix(
                mix(random_3d(cell_pos_3d_floored + vec3(0.0, 0.0, 1.0)), random_3d(cell_pos_3d_floored + vec3(1.0, 0.0, 1.0)), cell_pos_3d.x - cell_pos_3d_floored.x),
                mix(random_3d(cell_pos_3d_floored + vec3(0.0, 1.0, 1.0)), random_3d(cell_pos_3d_floored + vec3(1.0)), cell_pos_3d.x - cell_pos_3d_floored.x),
                smoothstep(0.0, 1.0, cell_pos_3d.y - cell_pos_3d_floored.y)
            ),
            smoothstep(0.0, 1.0, cell_pos_3d.z - cell_pos_3d_floored.z)
        ) * amplitude;
        cell_pos_3d *= 2.0;
        amplitude *= 0.65;
    }
    return total;
}

void main()
{
    vec3 normalmap = texture2D(s_normalMap, vec2(v_vTexcoord.x + time * 7.0, v_vTexcoord.y - time) * 6.0).rgb;
    vec2 offset = normalmap.xy * 2.0 - 1.0;
    
    gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
    vec4 reflected = texture2D(texture_sf_water_reflection, vec2(v_vTexcoord.x, 2.0 * reflection_y - v_vTexcoord.y) + offset * vec2(0.005, 0.01));
    gl_FragColor.rgb = mix(gl_FragColor.rgb, reflected.rgb, gl_FragColor.a * 0.3);
    
    gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(1.0), 0.02 * float(fractal_noise_3d(4, vec3(v_vTexcoord + vec2(time * 10.0, 0.0), time * 2.0), vec3(5.0, 50.0, 5.0)) < 0.5 - (1.0 - v_vTexcoord.y)));
}

