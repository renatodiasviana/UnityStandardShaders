Shader "Custom/SnowTesselationEffect"
{
	Properties
	{
		_Color("Color", color) = (1,1,1,0)
		_MainTex("Snow Base (RGB)", 2D) = "white" {}
		_GroundTex("Ground Tex (RGB)", 2D) = "white" {}
		_BlendNoiseTex("Blend Noise Tex (RGB)", 2D) = "white" {}
		_HightTex("Hight Map Texture", 2D) = "black" {}
		_Tess("Tessellation", Range(1,32)) = 4
		_Displacement("Displacement", Range(0, 1.0)) = 0.3
		_MaxDisplacement("Max Displacement", Range(0, 1.0)) = 0.3
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 300
		CGPROGRAM
		#pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap
		#pragma target 4.6

		#include "Tessellation.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_GroundTex;
			float2 uv_BlendNoiseTex;
		};

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _HightTex;
		sampler2D _GroundTex;
		sampler2D _BlendNoiseTex;

		float _Tess;
		float _Displacement;
		float _MaxDisplacement;

		float4 tessFixed()
		{
			return _Tess;
		}

		void disp(inout appdata v)
		{
			float3 hightMap = tex2Dlod(_HightTex, float4(v.texcoord.xy, 0, 0)).rgb;
			float d = min(length(hightMap) * _Displacement, _MaxDisplacement);
			v.vertex.xyz -= v.normal * d;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 snow = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			fixed4 hight = tex2D(_HightTex, IN.uv_MainTex);
			fixed4 ground = tex2D(_GroundTex, IN.uv_GroundTex);
			fixed4 noise = tex2D(_BlendNoiseTex, IN.uv_BlendNoiseTex);

			float4 finalColor = snow;
			if (hight.r >= _MaxDisplacement)
				finalColor = lerp(snow, ground, noise.r);

			o.Albedo = finalColor.rgb;
			o.Metallic = 0.1;
			o.Smoothness = 0.1;
			o.Alpha = 1.0;	
		}

		ENDCG

	} FallBack "Diffuse"
}
