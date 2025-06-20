#version 330 core
out vec4 fragmentColor;

in vec3 fragmentPosition;
in vec3 fragmentVertexNormal;
in vec2 TexCoords; // updated from fragmentTextureCoordinate

struct Material {
    vec3 diffuseColor;
    vec3 specularColor;
    float shininess;
}; 

struct DirectionalLight {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    bool bActive;
};

struct PointLight {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    bool bActive;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    float cutOff;
    float outerCutOff;
    float constant;
    float linear;
    float quadratic;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    bool bActive;
};

#define TOTAL_POINT_LIGHTS 5

uniform bool bUseTexture = false;
uniform bool bUseLighting = false;
uniform vec4 objectColor = vec4(1.0f);
uniform vec3 viewPosition;
uniform DirectionalLight directionalLight;
uniform PointLight pointLights[TOTAL_POINT_LIGHTS];
uniform SpotLight spotLight;
uniform Material material;
uniform sampler2D objectTexture;

vec3 CalcDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir);
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir);

void main()
{    
    if (bUseLighting == true)
    {
        vec3 phongResult = vec3(0.0f);
        vec3 norm = normalize(fragmentVertexNormal);
        vec3 viewDir = normalize(viewPosition - fragmentPosition);
    
        if (directionalLight.bActive == true)
        {
            phongResult += CalcDirectionalLight(directionalLight, norm, viewDir);
        }

        for (int i = 0; i < TOTAL_POINT_LIGHTS; i++)
        {
            if (pointLights[i].bActive == true)
            {
                phongResult += CalcPointLight(pointLights[i], norm, fragmentPosition, viewDir);   
            }
        } 

        if (spotLight.bActive == true)
        {
            phongResult += CalcSpotLight(spotLight, norm, fragmentPosition, viewDir);    
        }

        if (bUseTexture == true)
        {
            fragmentColor = vec4(phongResult, texture(objectTexture, TexCoords).a);
        }
        else
        {
            fragmentColor = vec4(phongResult, objectColor.a);
        }
    }
    else
    {
        if (bUseTexture == true)
        {
            fragmentColor = texture(objectTexture, TexCoords); // removed UVscale
        }
        else
        {
            fragmentColor = objectColor;
        }
    }
}

// === Lighting Calculation Functions ===

vec3 CalcDirectionalLight(DirectionalLight light, vec3 normal, vec3 viewDir)
{
    vec3 ambient, diffuse, specular;
    vec3 lightDirection = normalize(-light.direction);
    float diff = max(dot(normal, lightDirection), 0.0);
    vec3 reflectDir = reflect(-lightDirection, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    if (bUseTexture)
    {
        vec3 texColor = vec3(texture(objectTexture, TexCoords));
        ambient = light.ambient * texColor;
        diffuse = light.diffuse * diff * material.diffuseColor * texColor;
        specular = light.specular * spec * material.specularColor * texColor;
    }
    else
    {
        ambient = light.ambient * vec3(objectColor);
        diffuse = light.diffuse * diff * material.diffuseColor * vec3(objectColor);
        specular = light.specular * spec * material.specularColor;
    }

    return ambient + diffuse + specular;
}

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 ambient, diffuse, specular;
    vec3 lightDir = normalize(light.position - fragPos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float specComp = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    if (bUseTexture)
    {
        vec3 texColor = vec3(texture(objectTexture, TexCoords));
        ambient = light.ambient * texColor;
        diffuse = light.diffuse * diff * material.diffuseColor * texColor;
        specular = light.specular * specComp * material.specularColor;
    }
    else
    {
        ambient = light.ambient * vec3(objectColor);
        diffuse = light.diffuse * diff * material.diffuseColor * vec3(objectColor);
        specular = light.specular * specComp * material.specularColor;
    }

    return ambient + diffuse + specular;
}

vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 ambient, diffuse, specular;
    vec3 lightDir = normalize(light.position - fragPos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);

    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));    

    float theta = dot(lightDir, normalize(-light.direction)); 
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

    if (bUseTexture)
    {
        vec3 texColor = vec3(texture(objectTexture, TexCoords));
        ambient = light.ambient * texColor;
        diffuse = light.diffuse * diff * material.diffuseColor * texColor;
        specular = light.specular * spec * material.specularColor * texColor;
    }
    else
    {
        ambient = light.ambient * vec3(objectColor);
        diffuse = light.diffuse * diff * material.diffuseColor * vec3(objectColor);
        specular = light.specular * spec * material.specularColor;
    }

    ambient *= attenuation * intensity;
    diffuse *= attenuation * intensity;
    specular *= attenuation * intensity;
    return ambient + diffuse + specular;
}
