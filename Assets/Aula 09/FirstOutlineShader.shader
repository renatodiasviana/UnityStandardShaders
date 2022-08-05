Shader "Custom/FirstOutlineShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlinePower("Outline Power", Range(1,16)) = 2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 viewDir;
			INTERNAL_DATA
        };

        fixed4 _Color;
		fixed4 _OutlineColor;
		float _OutlinePower;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 baseColor = tex2D(_MainTex, IN.uv_MainTex);

			// Calcula o fresnell
			float fresnell = 1.0 - clamp(dot(IN.viewDir, o.Normal), 0.0, 1.0);

			// Potencia do outline
			float outlineIntensity = round(pow(fresnell, _OutlinePower));

			// MATEMÁTICA DE BLEND
			//float3 resultColor = baseColor.rgb * (1.0 - outlineIntensity) + _OutlineColor * outlineIntensity;
			float3 resultColor = lerp(baseColor, _OutlineColor, outlineIntensity);

			o.Albedo = resultColor * _Color;
			o.Alpha = baseColor.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
