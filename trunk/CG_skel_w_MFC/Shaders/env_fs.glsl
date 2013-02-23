#version 150 
// Fragment shader for ENV

#define MAX_LIGHTS 30

struct MaterialColor {
	vec3	emissive;
	vec3	diffuse;
	vec3	ambient;
	vec3	specular;
	float	shininess;
};

vec3 calcColor(in vec3 V, in vec3 N, in vec3 viewDir, in MaterialColor mc);

in vec3 normal;
in vec4 vertex;
in vec2 fTex;
in mat3 tbn;
out vec4 fcolor;

uniform	vec3 emissive;
uniform vec3 diffuse;
uniform vec3 ambient;
uniform vec3 specular;
uniform float shininess;

uniform samplerCube envCubeMap;
uniform bool useNormalMap;
uniform sampler2D normalMap;

uniform vec3 lightDir[MAX_LIGHTS];
uniform vec3 parlightColor[MAX_LIGHTS];
uniform int parallelLightNum;

uniform vec3 lightPos[MAX_LIGHTS];
uniform vec3 ptlightColor[MAX_LIGHTS];
uniform int pointLightNum;

void main()
{
	vec3 newNormal = normal;
	vec3 viewDir = normalize(-vertex.xyz);

	if( useNormalMap )
	{
		newNormal =  tbn * normalize( texture2D( normalMap, fTex ).rgb*2.0 - 1.0);
	}

	vec3 R = reflect(vertex.xyz, newNormal);
	vec4 texColor = texture(envCubeMap, R);

	MaterialColor mc;
	mc.diffuse = texColor.rgb;
	mc.specular = specular;
	mc.emissive = vec3(0,0,0); 
	mc.ambient = vec3(0,0,0); 
	mc.shininess = shininess * 10;

	vec3 totalColor = calcColor(vertex.xyz, newNormal, viewDir, mc);

	//fcolor = vec4(0.2, 0.2, 0.2, 1) * 0.7 + texColor * 0.3;
	fcolor = vec4(totalColor, 1); // * 0.7 + texColor * 0.3;
}

vec3 calcColor(in vec3 V, in vec3 N, in vec3 viewDir, in MaterialColor mc) 
{
	vec3 df = vec3(0,0,0);
	vec3 af = vec3(0,0,0);
	vec3 sf = vec3(0,0,0);
	vec3 ef = mc.emissive;
	for (int i = 0; i < parallelLightNum; i++)
	{
		vec3 L = normalize(lightDir[i]);
		float NdotL =  max(0.0, dot(N, -L ) );
		df += mc.diffuse * NdotL * parlightColor[i];
		if (NdotL > 0)
		{
			sf += mc.specular * parlightColor[i] * pow( max(   dot(reflect(L, N), viewDir),    0) , mc.shininess);
		}
	}
	for (int i = 0; i < pointLightNum; i++)
	{
		vec3 L = normalize(V - lightPos[i]);
		float NdotL =  max(0.0, dot(N, -L ) );
		df += mc.diffuse * NdotL * ptlightColor[i];
		if (NdotL > 0)
		{
			sf += mc.specular * ptlightColor[i] * pow( max(   dot(reflect(L, N), viewDir),    0) , mc.shininess);
		}
	}
	vec3 totalColor = df + af + sf + ef;
	return totalColor;
}
