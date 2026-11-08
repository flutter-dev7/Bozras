using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Non.Application.Common;
using Non.Application.Interfaces.Services;
using Non.Domain.Entities;
using Non.Domain.Enums;
using Non.Infrastructure.Persistence.Data;

namespace Non.Infrastructure.Persistence.Seeds;

public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var passwords = scope.ServiceProvider.GetRequiredService<IPasswordService>();

        await LocationSeeder.SeedAsync(context);
        await SeedSuperAdminAsync(context, configuration, passwords);
    }

    private static async Task SeedSuperAdminAsync(
        AppDbContext context, IConfiguration configuration, IPasswordService passwords)
    {
        if (await context.Users.AnyAsync(u => u.Role == UserRole.SuperAdmin))
            return;

        var email = EmailNormalizer.Normalize(configuration["Seed:SuperAdminEmail"]);
        if (email is null)
            return;

        if (await context.Users.AnyAsync(u => u.Email == email))
            return;

        var phone = PhoneNumberNormalizer.Normalize(configuration["Seed:SuperAdminPhone"])
            ?? throw new InvalidOperationException("Задайте Seed:SuperAdminPhone.");

        var password = configuration["Seed:SuperAdminPassword"];
        if (!string.IsNullOrEmpty(password))
        {
            var passwordError = PasswordRules.Validate(password);
            if (passwordError is not null)
                throw new InvalidOperationException($"Seed:SuperAdminPassword: {passwordError}");
        }

        context.Users.Add(new User
        {
            FirstName = configuration["Seed:SuperAdminFirstName"] ?? "Super",
            LastName = configuration["Seed:SuperAdminLastName"] ?? "Admin",
            Phone = phone,
            Email = email,
            EmailConfirmed = true,
            Role = UserRole.SuperAdmin,
            IsActive = true,
            PasswordHash = string.IsNullOrEmpty(password) ? null : passwords.Hash(password)
        });

        await context.SaveChangesAsync();
    }
}