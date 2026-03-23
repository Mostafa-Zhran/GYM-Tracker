using AutoMapper;
using GymBLL.DTO.AuthintcationDto;
using GymDAL.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymBLL.Mapper
{
    public class AuthProfile : Profile
    {
        public AuthProfile()
        {
            CreateMap<UserRegisterDto, ApplicationUser>()
                .ForMember(dest => dest.UserName,
                           opt => opt.MapFrom(src => src.UserName))
                .ReverseMap();
            CreateMap<AdminRegisterDto, ApplicationUser>()
                .ForMember(dest => dest.UserName,
                           opt => opt.MapFrom(src => src.UserName))
                .ReverseMap();
            CreateMap<AuthResponseDto, ApplicationUser>().ReverseMap();

        }
    }
}
