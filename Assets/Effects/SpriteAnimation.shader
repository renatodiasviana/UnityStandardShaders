Shader "Custom/SpriteAnimation"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_Speed("Animation Speed", Range(0,60)) = 30.0
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

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		half _Speed;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			half cols = 6.0;
			half rows = 4.0;

            // Albedo comes from a texture tinted by color
			half colsize = 1 / cols;   //percentual de tamanho
			half rowsize = 1 / rows;

			half t1 = _Time.y * _Speed;  //Controle de velocidade

			half px = floor(t1 % cols); 	          //contador (0,1,2)
			half py = floor((t1 / cols) % rows);  // Col x menor

			half x = (IN.uv_MainTex.x + px) * colsize;
			half y = (IN.uv_MainTex.y + py) * rowsize;
			half2 pos = half2(x, y);

			fixed4 c = tex2D(_MainTex, pos);
			o.Albedo = c.rgb;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
