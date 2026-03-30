import Foundation

// MARK: - Address

/// Postal address from `<address>` element.
/// Shared by owner, buddy, divebase, and maker.
public struct UDDFAddress: Codable, Sendable, Equatable {
    public let street: String?
    public let city: String?
    public let postcode: String?
    public let country: String?
    public let province: String?

    public init(
        street: String? = nil, city: String? = nil,
        postcode: String? = nil, country: String? = nil,
        province: String? = nil
    ) {
        self.street = street
        self.city = city
        self.postcode = postcode
        self.country = country
        self.province = province
    }
}

// MARK: - Contact

/// Contact information from `<contact>` element.
/// Shared by owner, buddy, divebase, and maker.
public struct UDDFContact: Codable, Sendable, Equatable {
    public let phone: String?
    public let mobilephone: String?
    public let fax: String?
    public let email: String?
    public let homepage: String?
    public let language: String?

    public init(
        phone: String? = nil, mobilephone: String? = nil,
        fax: String? = nil, email: String? = nil,
        homepage: String? = nil, language: String? = nil
    ) {
        self.phone = phone
        self.mobilephone = mobilephone
        self.fax = fax
        self.email = email
        self.homepage = homepage
        self.language = language
    }
}

// MARK: - Membership

/// Organization membership from `<membership>` element.
public struct UDDFMembership: Codable, Sendable, Equatable {
    public let organization: String?
    public let memberId: String?

    public init(organization: String? = nil, memberId: String? = nil) {
        self.organization = organization
        self.memberId = memberId
    }
}
