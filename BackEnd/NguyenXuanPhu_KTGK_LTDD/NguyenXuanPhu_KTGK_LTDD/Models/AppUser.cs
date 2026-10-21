using Microsoft.AspNetCore.Identity;
namespace NguyenXuanPhu_KTGK_LTDD.Api.Models;

public class AppUser : IdentityUser
{
    public string FullName { get; set; } = "";
    public string? CreatedByUserId { get; set; }
}
