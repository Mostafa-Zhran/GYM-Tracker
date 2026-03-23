using AutoMapper;
using GymBLL.DTO.AuthintcationDto;
using GymBLL.Manager.Authintcation;
using GymDAL.Model;
using GymDAL.Repository.Authintcation;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Sina_BLL.Manager.Authintcation
{
    public class AuthintcationManager : IAuthenticationManager
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _configuration;
        private readonly IAuthenticationRepository _authenticationRepository;
        private readonly IMapper _mapper;

        public AuthintcationManager(
            UserManager<ApplicationUser> userManager,
            IConfiguration configuration,
            IAuthenticationRepository authenticationRepository,
            IMapper mapper)
        {
            _userManager = userManager;
            _configuration = configuration;
            _authenticationRepository = authenticationRepository;
            _mapper = mapper;
        }

        #region ================= REGISTER CLIENT =================

        public async Task<AuthResponseDto> RegisterUserAsync(UserRegisterDto dto)
        {
            if (dto == null)
                throw new ArgumentNullException(nameof(dto));

            var existingUser = await _userManager.FindByEmailAsync(dto.Email);
            if (existingUser != null)
                return Failed("User already exists");

            if (dto.Password != dto.ConfirmPassword)
                return Failed("Passwords do not match");

            var user = _mapper.Map<ApplicationUser>(dto);
            user.UserName = dto.UserName;

            var result = await _authenticationRepository.User_RegisterAsync(user, dto.Password);

            if (!result.IsSuccess)
                return Failed(result.Error);

            // Add default role
            await _userManager.AddToRoleAsync(user, "Trainee");

            return await Success(user, "Trainee registered successfully");
        }

        #endregion

        #region ================= REGISTER ADMIN =================

        public async Task<AuthResponseDto> RegisterAdminAsync(AdminRegisterDto dto)
        {
            if (dto == null)
                throw new ArgumentNullException(nameof(dto));

            var existingUser = await _userManager.FindByEmailAsync(dto.Email);
            if (existingUser != null)
                return Failed("User already exists");

            if (dto.Password != dto.ConfirmPassword)
                return Failed("Passwords do not match");

            var user = _mapper.Map<ApplicationUser>(dto);
            user.UserName = dto.Email;

            var result = await _authenticationRepository.User_RegisterAsync(user, dto.Password);

            if (!result.IsSuccess)
                return Failed(result.Error);

            await _userManager.AddToRoleAsync(user, "Coach");

            return await Success(user, "Coach registered successfully");
        }

        #endregion

        #region ================= LOGIN =================

        public async Task<AuthResponseDto> LoginAsync(UserLoginDto dto)
        {
            if (dto == null)
                throw new ArgumentNullException(nameof(dto));

            var user = await _authenticationRepository.GetUserByEmailAsync(dto.Email);
            if (user == null)
                return Failed("Invalid email or password");

            var checkPassword = await _authenticationRepository.CheckPassword(user, dto.Password);
            if (!checkPassword.IsSuccess)
                return Failed("Invalid email or password");

            return await Success(user, "Login successful");
        }

        #endregion

        #region ================= SUCCESS RESPONSE =================

        private async Task<AuthResponseDto> Success(ApplicationUser user, string message)
        {
            var token = await GenerateToken(user);
            var roles = await _userManager.GetRolesAsync(user);

            var response = _mapper.Map<AuthResponseDto>(user);

            response.IsSuccess = true;
            response.Message = message;
            response.Token = token;
            response.Roles = roles.ToList();
            response.CoachId = user.CoachId;
            return response;
        }

        #endregion

        #region ================= FAILED RESPONSE =================

        private AuthResponseDto Failed(string message)
        {
            return new AuthResponseDto
            {
                IsSuccess = false,
                Message = message
            };
        }

        #endregion

        #region ================= JWT GENERATION =================

        private async Task<string> GenerateToken(ApplicationUser user)
        {
            var jwtSection = _configuration.GetSection("Jwt");

            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSection["Key"])
            );

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Name, user.UserName ?? "")
            };

            var roles = await _userManager.GetRolesAsync(user);
            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
            }

            var token = new JwtSecurityToken(
                issuer: jwtSection["Issuer"],
                audience: jwtSection["Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(
                    Convert.ToDouble(jwtSection["DurationInMinutes"])
                ),
                signingCredentials: new SigningCredentials(
                    key,
                    SecurityAlgorithms.HmacSha256
                )
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        #endregion
    }
}