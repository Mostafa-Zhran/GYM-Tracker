using Google.Apis.Auth;
using GymBLL.DTO.AuthintcationDto;
using GymBLL.Exceptions;
using GymBLL.Manager.Authintcation;
using GymDAL.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;


namespace Sina_API.Controllers.Account
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountController : ControllerBase
    {
        private readonly IAuthenticationManager _AuthenticationManager;
        private readonly UserManager<ApplicationUser> _UserManager;

        public AccountController(IAuthenticationManager authenticationManager , UserManager<ApplicationUser> userManager)
        {
            _AuthenticationManager = authenticationManager;
            _UserManager = userManager;
        }

        [HttpPost("Register/User")]
        public async Task<IActionResult> RegistrationUser(UserRegisterDto userRegister)
        {
            if (userRegister == null)
            {
                throw new BadRequestException("User Not Exist");
            }

            var Response = await _AuthenticationManager.RegisterUserAsync(userRegister);

            return Ok(Response);
        }

        [HttpPost("Register/Admin")]
        public async Task<IActionResult> RegistrationAdmin(AdminRegisterDto userRegister)
        {
            if (userRegister == null)
            {
                throw new BadRequestException("Admin Not Exist");
            }

            var Response = await _AuthenticationManager.RegisterAdminAsync(userRegister);

            return Ok(Response);
        }

        [HttpPost("Login")]
        public async Task<IActionResult> Login(UserLoginDto userLogin)
        {
            if (userLogin == null)
            {
                throw new BadRequestException(" this User Not Exist");
            }
            var Response = await _AuthenticationManager.LoginAsync(userLogin);
            return Ok(Response);
        }

        [HttpGet("Coahes")]
        public async Task<IActionResult> GetAllCoaches()
        {
            var coaches = await _UserManager.GetUsersInRoleAsync("Coach");

            var result = coaches.Select(c => new
            {
                id = c.Id,
                name = c.UserName,
                email = c.Email
            });

            return Ok(result);
        }
    }
}
