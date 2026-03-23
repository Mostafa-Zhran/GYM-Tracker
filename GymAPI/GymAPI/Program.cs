using GymBLL.Manager.Authintcation;
using GymBLL.Mapper;
using GymDAL.DB;
using GymDAL.Model;
using GymDAL.Repository.Authintcation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Sina_BLL.Manager.Authintcation;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// =============================
// 1️⃣ Database
// =============================
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")));

// =============================
// 2️⃣ Identity
// =============================
builder.Services
    .AddIdentity<ApplicationUser, IdentityRole>(options =>
    {
        options.Password.RequireDigit = false;
        options.Password.RequireUppercase = false;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequiredLength = 6;
    })
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

// =============================
// 3️⃣ JWT Authentication
// =============================
var jwtKey = builder.Configuration["Jwt:Key"];


builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)),
            // ✅ Tell ASP.NET which claim is the user ID
            NameClaimType = ClaimTypes.NameIdentifier,
        };

        // ✅ Required for SignalR — reads token from query string
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/chatHub"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

// =============================
// 4️⃣ Authorization
// =============================
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CoachOnly",
        policy => policy.RequireRole("Coach"));
});

// =============================
// 5️⃣ CORS (Flutter + SignalR)
// =============================
builder.Services.AddCors(options =>
{
    // ✅ REST API endpoints — Flutter mobile + web
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyHeader()
              .AllowAnyMethod()
              .AllowAnyOrigin(); // ✅ works for REST
    });

    // ✅ SignalR hub — needs AllowCredentials, cannot use AllowAnyOrigin
    options.AddPolicy("SignalRPolicy", policy =>
    {
        policy.AllowAnyHeader()
              .AllowAnyMethod()
              .SetIsOriginAllowed(_ => true) // ✅ allows any origin
              .AllowCredentials();           // ✅ required for WebSockets
    });
});

// =============================
// 6️⃣ AutoMapper
// =============================
builder.Services.AddAutoMapper(cfg =>
{
    cfg.AddProfile<AuthProfile>();
}, AppDomain.CurrentDomain.GetAssemblies());

// =============================
// 7️⃣ Dependency Injection
// =============================
builder.Services.AddScoped<IAuthenticationRepository, AuthenticationRepository>();
builder.Services.AddScoped<IAuthenticationManager, AuthintcationManager>();

// =============================
// 8️⃣ SignalR
// =============================
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, NameIdentifierUserIdProvider>();

// =============================
// 9️⃣ Controllers
// =============================
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// =============================
// 🔟 Swagger + JWT
// =============================
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Gym API", Version = "v1" });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter token: Bearer {your token}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id   = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// =============================
// Build App
// =============================
var app = builder.Build();

// =============================
// Seed Roles
// =============================
using (var scope = app.Services.CreateScope())
{
    var roleManager =
        scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

    foreach (var role in new[] { "Coach", "Trainee" })
    {
        if (!await roleManager.RoleExistsAsync(role))
            await roleManager.CreateAsync(new IdentityRole(role));
    }
}

// =============================
// Middleware Pipeline
// =============================
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("AllowAll");        // ✅ applies to all REST controllers

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.MapHub<ChatHub>("/chatHub")
   .RequireCors("SignalRPolicy"); // ✅ SignalR gets its own CORS policy
app.Run(); // ✅ ADD THIS — your file is missing it
