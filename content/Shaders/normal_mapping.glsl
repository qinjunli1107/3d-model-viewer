Copyright (c) 2006-2007 dhpoware. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

-------------------------------------------------------------------------------

Tangent space normal mapping shader for a single directional light source.

The tangent vector is passed to the vertex shader in gl_MultiTexCoord1. The
tangent vector is assumed to be a four component vector. The tangent vector's
w component indicates the handedness of the local tangent space at this vertex.
The handedness is used to calculate the bitangent vector. The reason for the
inclusion of the handedness component is to allow for triangles with mirrored
texture mappings.

-------------------------------------------------------------------------------

[vert]

#version 110

varying vec3 lightDir;
varying vec3 halfVector;

void main()
{
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    vec3 n = normalize(gl_NormalMatrix * gl_Normal);
    vec3 t = normalize(gl_NormalMatrix * gl_MultiTexCoord1.xyz);
    vec3 b = cross(n, t) * gl_MultiTexCoord1.w;
        
    mat3 tbnMatrix = mat3(t.x, b.x, n.x,
                          t.y, b.y, n.y,
                          t.z, b.z, n.z);

    lightDir = gl_LightSource[0].position.xyz;
    lightDir = tbnMatrix * lightDir;

    halfVector = gl_LightSource[0].halfVector.xyz;
    halfVector = tbnMatrix * halfVector;
}

[frag]

#version 110

uniform sampler2D colorMap;
uniform sampler2D normalMap;
uniform float materialAlpha;

varying vec3 lightDir;
varying vec3 halfVector;

void main()
{
    vec3 n = normalize(texture2D(normalMap, gl_TexCoord[0].st).rgb * 2.0 - 1.0);
    vec3 l = normalize(lightDir);
    vec3 h = normalize(halfVector);

    float nDotL = max(0.0, dot(n, l));
    float nDotH = max(0.0, dot(n, h));
    float power = (nDotL == 0.0) ? 0.0 : pow(nDotH, gl_FrontMaterial.shininess);
    
    vec4 ambient = gl_FrontLightProduct[0].ambient;
    vec4 diffuse = gl_FrontLightProduct[0].diffuse * nDotL;
    vec4 specular = gl_FrontLightProduct[0].specular * power;
    vec4 color = gl_FrontLightModelProduct.sceneColor + ambient + diffuse + specular;
    
    gl_FragColor = color * texture2D(colorMap, gl_TexCoord[0].st);
    gl_FragColor.a = materialAlpha;
}
