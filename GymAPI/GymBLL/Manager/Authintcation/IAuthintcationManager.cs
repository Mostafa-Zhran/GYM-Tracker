using Google.Apis.Auth;
using GymBLL.DTO.AuthintcationDto;
using GymBLL.DTO.AuthintcationDto;
using GymDAL.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymBLL.Manager.Authintcation
{
    public interface IAuthenticationManager
    {
        Task<AuthResponseDto> RegisterUserAsync(UserRegisterDto userRegister);
        Task<AuthResponseDto> RegisterAdminAsync(AdminRegisterDto userRegister);
        Task<AuthResponseDto> LoginAsync(UserLoginDto loginDto);
    }
}
