using ApartmanApp.Business.DTOs.Aidat;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class AidatCreateValidator : AbstractValidator<AidatCreateDto>
{
    public AidatCreateValidator()
    {
        RuleFor(x => x.KullaniciId)
            .GreaterThan(0).WithMessage("Geçerli bir kullanıcı ID girilmelidir.");

        RuleFor(x => x.Tutar)
            .GreaterThan(0).WithMessage("Tutar sıfırdan büyük olmalıdır.")
            .LessThanOrEqualTo(1_000_000).WithMessage("Tutar çok yüksek.");

        RuleFor(x => x.Ay)
            .InclusiveBetween(1, 12).WithMessage("Ay 1 ile 12 arasında olmalıdır.");

        RuleFor(x => x.Yil)
            .InclusiveBetween(2020, 2100).WithMessage("Yıl 2020 ile 2100 arasında olmalıdır.");
    }
}
