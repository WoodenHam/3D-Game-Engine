Texture2D EarthColor: register(t0);
sampler EarthColorSampler: register(s0);

Texture2D EarthSpecular: register(t1);
sampler EarthSpecularSampler: register(s1);

Texture2D Clouds: register(t2);
sampler CloudsSampler: register(s2);

Texture2D EarthNight: register(t3);
sampler EarthNightSampler: register(s3);

struct PS_INPUT
{
	float4 position: SV_POSITION;
	float2 texcoord: TEXCOORD0;
	float3 normal: NORMAL0;
	float3 direction_to_camera: TEXCOORD1;
};

cbuffer constant: register(b0)
{
	row_major float4x4 m_world;
	row_major float4x4 m_view;
	row_major float4x4 m_proj;
	float4 m_light_direction;
	float4 m_camera_position;
	float m_time;
};

float4 psmain(PS_INPUT input) : SV_TARGET
{
	float4 earth_color = EarthColor.Sample(EarthColorSampler, 1.0 - input.texcoord);
	float earth_spec = EarthSpecular.Sample(EarthSpecularSampler, 1.0 - input.texcoord).r;
	float clouds = Clouds.Sample(CloudsSampler, 1.0 - input.texcoord + float2(m_time / 100.0, 0)).r;
	float4 earth_night = EarthNight.Sample(EarthNightSampler, 1.0 - input.texcoord);

	//Ambient Light
	float ka = 1.5;							//Constant ambient light amount
	float3 ia = float3(0.09, 0.082, 0.082);		//Ambient light colour
	ia *= (earth_color.rgb);

	float3 ambient_light = ka * ia;

	//Diffuse Light
	float kd = 0.7;							//Constant diffuse light amount
	float3 id_day = float3(1.0, 1.0, 1.0);		//Diffuse light colour
	id_day *= (earth_color.rgb + clouds);

	float3 id_night = float3(1.0, 1.0, 1.0);
	id_night *= (earth_night.rgb + clouds * 0.3);

	float amount_diffuse_light = dot(m_light_direction.xyz, input.normal);

	float3 id = lerp(id_night, id_day, (amount_diffuse_light + 1.0) / 2.0);

	float3 diffuse_light = kd * id;

	//Specular Light
	float ks = earth_spec;							//Constant specular light amount
	float3 is = float3(1.0, 1.0, 1.0);		//Specular light colour
	float3 reflected_light = reflect(m_light_direction.xyz, input.normal);
	float specularity = 30.0;				//Decreasing this makes model more shiny because maths
	float amount_specular_light = pow(max(0.0, dot(reflected_light, input.direction_to_camera)), specularity);

	float3 specular_light = ks * amount_specular_light * is;

	float3 final_light = ambient_light + diffuse_light + specular_light;

	//Phong reflection model
	return float4(final_light, 1.0);
}