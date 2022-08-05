Shader "Custom/FirstStylizedShading"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_StylizedMaskTex("Stylized Shading Mask", 2D) = "white" {}
		_Shininess("Shininess", Range(0.0001, 1.0)) = 0.5
		_Tones("Number of Tones", Range(2, 20.0)) = 5.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM

		#pragma surface surf MyCustomLighting fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _StylizedMaskTex;
		half _Shininess;
		half _Tones;
		fixed4 _Color;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_StylizedMaskTex;
		};

		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 MaskShading;
			fixed3 Emission;
			fixed Shininess;
			fixed Alpha;
		};

		float4 LightingMyCustomLighting(SurfaceOutputCustom s, half3 lightDir, half3 viewDir, half atten)
		{
			// Calculate Diffuse light
			half NdotL = clamp(dot(s.Normal, lightDir) * atten, 0.0, 1.0);

			half finalNdotL = lerp(s.MaskShading * NdotL, NdotL, NdotL);

			float3 diffuseColor = s.Albedo * _LightColor0.rgb * finalNdotL;

			// Calculate Specular light
			float3 halfVector = normalize(lightDir + viewDir);
			half NdotH = clamp(dot(s.Normal, halfVector), 0.0, 0.9);

			half finalNdotH = lerp(s.MaskShading * NdotH, NdotH, NdotH);

			finalNdotH = round(pow(finalNdotH, _Shininess * 32.0) * _Tones) / _Tones;

			float3 specularColor = s.Albedo * _LightColor0.rgb * finalNdotH;

			float4 resultColor = float4(0.0, 0.0, 0.0, 1.0);
			resultColor.rgb = clamp(diffuseColor + specularColor, 0.0, 1.0);

			float VdotN = clamp(dot(viewDir, s.Normal), 0.0, 1.0);
			return resultColor * VdotN;
		}

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputCustom o)
		{
			fixed4 mask = tex2D(_StylizedMaskTex, IN.uv_StylizedMaskTex);
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

			c.rgb = round(c.rgb * _Tones) / _Tones;

			o.Albedo = c.rgb;
			o.MaskShading = mask.rgb;
			o.Shininess = _Shininess;
			o.Alpha = 1.0;
		}

		ENDCG
	}

	FallBack "Diffuse"
}