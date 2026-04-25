using FluentValidation;

namespace ApartmanApp.Business.Validators;

/// Şifre karmaşıklık kuralları — tüm şifre alanları için ortak
public static class SifrePolicy
{
    public static IRuleBuilderOptions<T, string> StrongPassword<T>(
        this IRuleBuilder<T, string> rule) =>
        rule
            .NotEmpty().WithMessage("Şifre boş olamaz.")
            .MinimumLength(8).WithMessage("Şifre en az 8 karakter olmalıdır.")
            .MaximumLength(100).WithMessage("Şifre en fazla 100 karakter olabilir.")
            .Matches("[A-Za-zÇĞİÖŞÜçğıöşü]").WithMessage("Şifre en az bir harf içermelidir.")
            .Matches("[0-9]").WithMessage("Şifre en az bir rakam içermelidir.");
}
