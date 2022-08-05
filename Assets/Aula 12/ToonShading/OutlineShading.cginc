struct appdata
{
	float4 pos : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float4 worldPos : COLOR;
	LIGHTING_COORDS(2, 3)
};

sampler2D _MainTex;

float4 _MainTex_ST;

v2f vert(appdata v)
{
	v2f o;

	o.pos = UnityObjectToClipPos(v.pos);
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.worldPos = mul(unity_ObjectToWorld, v.pos);

	TRANSFER_VERTEX_TO_FRAGMENT(o);

	return o;
}