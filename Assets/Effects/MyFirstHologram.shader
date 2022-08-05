Shader "Custom/MyFirstHologram"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_NormalTex("Mapa de normal (RGB)", 2D) = "bump" {}
		_MetallicTex("Mettalic map (RGB)", 2D) = "black" {}
		_RoughnessTex("Roughness map (RGB)", 2D) = "black" {}
		_EmissionTex("Emission map (RGB)", 2D) = "black" {}
		_NoiseTex("Noise map (RGB)", 2D) = "black" {}
		_NumberOfWaves("Number of waves", Range(0,90)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:blend

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		sampler2D _NormalTex;
		sampler2D _MetallicTex;
		sampler2D _RoughnessTex;
		sampler2D _EmissionTex;
		sampler2D _NoiseTex;
		half _NumberOfWaves;

        struct Input
        {
            float2 uv_NormalTex;
			float3 worldPos; // --> Posição do pixel no pixel
        };

        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
			// Albedo comes from a texture tinted by color
			fixed3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex)).rgb;
			fixed4 metallicMap = tex2D(_MetallicTex, IN.uv_NormalTex);
			fixed4 roughnessMap = tex2D(_RoughnessTex, IN.uv_NormalTex);
			fixed4 emissionMap = tex2D(_EmissionTex, IN.uv_NormalTex);
			fixed4 noiseMap = tex2D(_NoiseTex, IN.uv_NormalTex);

			o.Albedo = _Color.rgb;

			o.Normal = normalMap;
			o.Metallic = metallicMap.r;

			// Transformando roughness em smoothness
			float smoothness = (1.0 - roughnessMap.r);
			o.Smoothness = smoothness;

			o.Emission = length(emissionMap.rgb) * _Color.rgb;

			float yPosition = IN.worldPos.y + (_Time.y * 0.5) + noiseMap.r;

			//float finalSin = (sin(yPosition * _NumberOfWaves) + 1.0) * 0.5;
			float finalSin = clamp(sin(yPosition * _NumberOfWaves), 0.0, 1.0); 

			o.Alpha = finalSin;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
