#include "UnityCG.cginc"
#include "AutoLightFixed.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "MyTessellation.cginc"

#pragma require geometry
#pragma require tessellation

struct appdata
{
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
};

struct v2g
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : tangent;
	float4 color : COLOR;
	//float hight : FLOAT;
};

struct g2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 tangent : TEXCOORD2;
	//float hight : FLOAT;
	float4 color : COLOR;
	LIGHTING_COORDS(3, 4)
};

fixed4 _Color;
fixed4 _BaseGrassColor;

sampler2D _MainTex;
sampler2D _GrassGroupTex;
sampler2D _HightNoiseTex;
sampler2D _DistributionMaskTex;
sampler2D _WindDirTex;
sampler2D _CollisionDirTex;

float4 _MainTex_ST;
float4 _GrassGroupTex_ST;
float4 _HightNoiseTex_ST;
float4 _DistributionMaskTex_ST;
float4 _WindDirTex_ST;

float _GrassHight;
float _GrassCount;
float _GrassLength;
float _GrassSegmentCount;
float _DistributionGrassController;
float _WindFrequencyController;
float _ShadingTones;
float _Shininess;
float4 _WindDir;

static float RandomSeed = 1.0;

// Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 angleAxis3x3(float angle, float3 axis)
{
	float c, s;
	sincos(angle, s, c);

	float t = 1 - c;
	float x = axis.x;
	float y = axis.y;
	float z = axis.z;

	return float3x3(t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c);
}

float CalculateRandomValue(float3 co)
{
	return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

float CalculateRandomValue(float min, float max)
{
	float randomno = CalculateRandomValue(RandomSeed);

	RandomSeed++;

	return lerp(min, max, randomno);
}

float RandomPos(float noise)
{
	return CalculateRandomValue(-0.5 * noise, 0.5 * noise);
}

// Vertex shader
v2g vert(appdata v)
{
	v2g o;

	o.pos = v.pos;
	o.uv = v.uv;
	o.normal = v.normal;
	o.tangent = v.tangent;
	o.color = float4(1.0, 1.0, 1.0, 1.0);

	return o;
}

// Declaring tessellation hull function
TESS_PATCH_FUNC(MyPatchFunc, appdata, _GrassCount)
TESS_HULL_FUNC(MyHullFunc, "MyPatchFunc", appdata, "fractional_odd")
TESS_DOMAIN_FUNC(MyDomainFunc, vert, appdata, v2g)

// Geometry Shader
g2f geo_to_frag(v2g v)
{
	g2f o;

	o.pos = UnityObjectToClipPos(v.pos);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.tangent = UnityObjectToWorldNormal(v.normal);
	o.color = v.color;
	//o.hight = v.hight;
	TRANSFER_VERTEX_TO_FRAGMENT(o);

	return o;
}

void generateGrassSegment(v2g v1, v2g v2, v2g v3, v2g v4, inout TriangleStream<g2f> triStream)
{
	float3 v2v1 = normalize(v2.pos - v1.pos);
	float3 v3v1 = normalize(v3.pos - v1.pos);
	float3 normal1 = normalize(cross(v2v1, v3v1));

	float3 v4v2 = normalize(v4.pos - v2.pos);
	float3 v3v2 = normalize(v3.pos - v2.pos);
	float3 normal2 = normalize(cross(v4v2, v3v2));

	v1.normal = normalize(normal1 + normal2 + v1.normal * 10.0f);
	v2.normal = normalize(normal1 + normal2 + v2.normal * 10.0f);
	v3.normal = normalize(normal1 + normal2 + v3.normal * 10.0f);
	v4.normal = normalize(normal1 + normal2 + v4.normal * 10.0f);

	triStream.Append(geo_to_frag(v1));
	triStream.Append(geo_to_frag(v2));
	triStream.Append(geo_to_frag(v3));
	triStream.Append(geo_to_frag(v4));

	triStream.RestartStrip();
}

v2g CalculateVertex(v2g input, float hight, float colorIntensity, float2 uv, float4 vertexOffSet)
{
	v2g v = input;
	v.color = lerp(_BaseGrassColor, _Color, colorIntensity);
	v.pos += vertexOffSet;
	v.uv = uv;
	v.normal = input.normal;
	//v.hight = hight;

	return v;
}

void generateGrass(v2g vData, float4 wind, float noise, float3 offset, inout TriangleStream<g2f> triStream)
{
	v2g v1, v2, v3, v4;

	float4 segmentHight = float4(0.0, 0.0, 0.0, 0.0);
	float colorIntensity = 1.0 / _GrassSegmentCount;
	float uvY = 0.0;
	float4 windAnimation = 0.0;

	float grassSide = CalculateRandomValue(0.0, 1.0) < 0.5 ? -1.0 : 1.0;

	for (int i = 0; i < (int) _GrassSegmentCount; i++)
	{
		float hight = clamp(noise, 0.15, 1.0);
		float noiseHight = lerp(0.5, 1.0, CalculateRandomValue(hight)) * _GrassHight;

		v1 = CalculateVertex(vData, hight, colorIntensity, float2(0.0, uvY), float4(offset * grassSide, 0.0) + segmentHight + windAnimation);
		v2 = CalculateVertex(vData, hight, colorIntensity, float2(1.0, uvY), float4(offset * grassSide * -1.0, 0.0) + segmentHight + windAnimation);

		// Updating data for the upper vertex
		colorIntensity += 1.0 / _GrassSegmentCount;
		uvY += 1.0 / _GrassSegmentCount;

		windAnimation += (wind * (2.0 / _GrassSegmentCount)) * pow(noise, 2.0);

		v3 = CalculateVertex(vData, hight, colorIntensity, float2(0.0, uvY),
							float4(offset * grassSide, 0.0) + float4(vData.normal * noiseHight, 0.0) + segmentHight + windAnimation);

		v4 = CalculateVertex(vData, hight, colorIntensity, float2(1.0, uvY),
							float4(offset * grassSide * -1.0, 0.0) + float4(vData.normal * noiseHight, 0.0) + segmentHight + windAnimation);

		generateGrassSegment(v1, v2, v3, v4, triStream);

		segmentHight += float4(0.0, noiseHight, 0.0, 0.0);
	}
}

v2g GetBaryCentric(v2g IN[3])
{
	v2g baryCentric;

	baryCentric.pos = (IN[0].pos + IN[1].pos + IN[2].pos) / 3.0;
	baryCentric.normal = (IN[0].normal + IN[1].normal + IN[2].normal) / 3.0;
	baryCentric.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3.0;
	baryCentric.tangent = (IN[0].tangent + IN[1].tangent + IN[2].tangent) / 3.0;

	return baryCentric;
}

[maxvertexcount(50)]
void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
{
	g2f o;

	fixed4 noise;

	v2g baryCentric = GetBaryCentric(IN);

	float2 uv = TRANSFORM_TEX(baryCentric.uv, _DistributionMaskTex);
	float4 distributionNoise = tex2Dlod(_DistributionMaskTex, float4(uv, 0, 0));
	if (distributionNoise.r > _DistributionGrassController)
		return;

	//for (int i = 0; i < 20; i++)
	{
		//float randomAngle = CalculateRandomValue(baryCentric.pos.zzx * (float) 0.0 * 10.0) * 360.0;
		float randomAngle = CalculateRandomValue(baryCentric.pos.zzx * CalculateRandomValue(0.0, 360.0));
		float3x3 randomRotation = angleAxis3x3(randomAngle, float3(0.0, 1.0, 0.0));
		float3 offset = normalize(mul(randomRotation, float4(0.25, 0.0, 0.25, 1.0)).xyz) * 0.1 * _GrassLength;

		//float3 offset = float3(0.1, 0.0, 0.0) * _GrassLength;

		float4 noise = tex2Dlod(_HightNoiseTex, float4(baryCentric.uv, 0, 0));

		float2 windUV = baryCentric.uv + float2(0.1, 0.1) * (sin(_Time.y * 0.1)) * _WindFrequencyController * 2.0;
		windUV = TRANSFORM_TEX(windUV, _WindDirTex);

		float4 wind = float4(UnpackNormal(tex2Dlod(_WindDirTex, float4(windUV, 0, 0))), 1.0) * _WindDir;
		float4 collisionMask = tex2Dlod(_CollisionDirTex, float4(baryCentric.uv, 0, 0));

		float4 distortion = wind * 0.1;
		if (length(collisionMask.rgb) != 0.0)
		{
			collisionMask = float4(UnpackNormal(collisionMask), 0.0);
			distortion = collisionMask * 0.15 + wind * 0.001;
		}

		generateGrass(baryCentric, distortion, noise.x, offset, triStream);
	}
}
