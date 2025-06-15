<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Employee Management
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAdminRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isEmployeeFormOpen" @update:open="isEmployeeFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewEmployee">Add New Employee</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6">
            <DialogHeader>
              <DialogTitle>{{
                isEditingEmployee ? "Edit Employee" : "Add New Employee"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditingEmployee
                    ? "Update employee details."
                    : "Add a new employee to the list."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveEmployee" class="space-y-4 py-4">
              <div>
                <Label for="employeeEmail" class="mb-2">Email</Label>
                <Input
                  id="employeeEmail"
                  v-model="employeeForm.email"
                  type="email"
                  :disabled="isEditingEmployee"
                  required
                />
              </div>
              <div>
                <Label for="employeeFullName" class="mb-2">Full Name</Label>
                <Input
                  id="employeeFullName"
                  v-model="employeeForm.full_name"
                  type="text"
                />
              </div>
              <div v-if="!isEditingEmployee">
                <Label for="employeePassword" class="mb-2">Password</Label>
                <Input
                  id="employeePassword"
                  v-model="employeeForm.password"
                  type="password"
                  required
                />
              </div>
              <div>
                <Label for="employeeRole" class="mb-2">Role</Label>
                <Select v-model="employeeForm.role">
                  <SelectTrigger>
                    <SelectValue placeholder="Select a role" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectGroup>
                      <SelectItem value="cashier">Cashier</SelectItem>
                      <SelectItem value="manager">Manager</SelectItem>
                      <SelectItem value="admin">Admin</SelectItem>
                    </SelectGroup>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label for="employeePhone" class="mb-2">Phone</Label>
                <Input id="employeePhone" v-model="employeeForm.phone" type="text" />
              </div>
              <div>
                <Label for="employeeAddress" class="mb-2">Address</Label>
                <Textarea id="employeeAddress" v-model="employeeForm.address" />
              </div>
              <div class="flex items-center space-x-2">
                <Checkbox id="employeeIsActive" v-model="employeeForm.is_active" />
                <Label for="employeeIsActive">Active</Label>
              </div>
              <div
                v-if="addEmployeeMessage"
                :class="{
                  'text-green-500': !addEmployeeError,
                  'text-red-500': addEmployeeError,
                }"
                class="text-sm mt-2"
              >
                {{ addEmployeeMessage }}
              </div>
              <DialogFooter>
                <Button type="submit" :disabled="loadingAddEmployee">
                  <span v-if="loadingAddEmployee">Saving...</span>
                  <span v-else>{{
                    isEditingEmployee ? "Update Employee" : "Add Employee"
                  }}</span>
                </Button>
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEditEmployee"
                    >Cancel</Button
                  >
                </DialogClose>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Employee List
        </h2>
        <div v-if="loadingEmployees" class="text-center text-gray-500 dark:text-gray-400">
          Loading employees...
        </div>
        <div
          v-else-if="employees.length === 0"
          class="text-center text-gray-500 dark:text-gray-400"
        >
          No employees found.
        </div>
        <Table v-else>
          <TableHeader>
            <TableRow>
              <TableHead>Email</TableHead>
              <TableHead>Full Name</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Phone</TableHead>
              <TableHead>Address</TableHead>
              <TableHead>Active</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="employee in employees" :key="employee.id">
              <TableCell>{{ employee.email }}</TableCell>
              <TableCell>{{ employee.full_name }}</TableCell>
              <TableCell>{{ employee.role }}</TableCell>
              <TableCell>{{ employee.phone }}</TableCell>
              <TableCell>{{ employee.address }}</TableCell>
              <TableCell>{{ employee.is_active ? "Ya" : "Tidak" }}</TableCell>
              <TableCell>
                <Button @click="editEmployee(employee)" size="sm" class="mr-2"
                  >Edit</Button
                >
                <Button
                  @click="confirmDeleteEmployee(employee.id)"
                  size="sm"
                  variant="destructive"
                  >Delete</Button
                >
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Delete Employee</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this employee? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Cancel</Button>
            <Button
              variant="destructive"
              @click="deleteEmployeeConfirmed"
              :disabled="loadingAddEmployee"
            >
              <span v-if="loadingAddEmployee">Deleting...</span>
              <span v-else>Delete</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";
import type { User } from "@supabase/supabase-js";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: "admin" | "manager" | "cashier";
  phone: string | null;
  address: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();
const router = useRouter();

const userProfile = ref<UserProfile | null>(null);
const employees = ref<UserProfile[]>([]);
const loadingEmployees = ref(true);
const loadingAddEmployee = ref(false);
const addEmployeeMessage = ref("");
const addEmployeeError = ref(false);

const isEmployeeFormOpen = ref(false); // Controls the add/edit employee dialog
const isEditingEmployee = ref(false); // True if editing an existing employee, false if adding new
const employeeForm = ref({
  id: "",
  email: "",
  full_name: "",
  password: "",
  role: "cashier" as "admin" | "manager" | "cashier",
  phone: "",
  address: "",
  is_active: true,
});
const employeeToDeleteId = ref<string | null>(null); // Stores the ID of the employee to be deleted
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog

const fetchUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    console.error("Error fetching user profile:", error.message);
    userProfile.value = null;
  } else {
    userProfile.value = data as UserProfile;
  }
};

const fetchEmployees = async () => {
  loadingEmployees.value = true;
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Error fetching employees:", error.message);
  } else {
    employees.value = data as UserProfile[];
    console.log("Fetched employees:", employees.value); // Log fetched data
  }
  loadingEmployees.value = false;
};

const saveEmployee = async () => {
  loadingAddEmployee.value = true;
  addEmployeeMessage.value = "";
  addEmployeeError.value = false;

  try {
    if (isEditingEmployee.value) {
      console.log("Attempting to update employee:", employeeForm.value); // Log before update
      // Update existing employee
      const { error } = await supabase
        .from("profiles")
        .update({
          full_name: employeeForm.value.full_name,
          phone: employeeForm.value.phone,
          address: employeeForm.value.address,
          role: employeeForm.value.role,
          is_active: employeeForm.value.is_active,
        })
        .eq("id", employeeForm.value.id);

      console.log("Supabase update error:", error); // Log error after update

      if (error) throw error;
      addEmployeeMessage.value = "Employee updated successfully!";
    } else {
      // Add new employee
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: employeeForm.value.email,
        password: employeeForm.value.password,
        options: {
          data: {
            full_name: employeeForm.value.full_name,
            role: employeeForm.value.role,
          },
        },
      });

      if (authError) throw authError;

      if (employeeForm.value.role !== "cashier" && authData.user) {
        const { error: profileUpdateError } = await supabase
          .from("profiles")
          .update({ role: employeeForm.value.role })
          .eq("id", authData.user.id);

        if (profileUpdateError) throw profileUpdateError;
      }
      addEmployeeMessage.value =
        "Employee added successfully! An email has been sent for confirmation.";
    }
    await fetchEmployees();
    resetForm();
    isEmployeeFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    console.error("Error saving employee:", error.message);
    addEmployeeMessage.value = "Failed to save employee: " + error.message;
    addEmployeeError.value = true;
  } finally {
    loadingAddEmployee.value = false;
  }
};

const addNewEmployee = () => {
  resetForm();
  isEmployeeFormOpen.value = true;
};

const editEmployee = (employee: UserProfile) => {
  isEditingEmployee.value = true;
  employeeForm.value = {
    ...employee,
    password: "", // Clear password when editing
    is_active: Boolean(employee.is_active), // Ensure is_active is a boolean
  };
  addEmployeeMessage.value = "";
  addEmployeeError.value = false;
  isEmployeeFormOpen.value = true; // Open the dialog for editing
};

const cancelEditEmployee = () => {
  resetForm();
  isEmployeeFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteEmployee = (employeeId: string) => {
  employeeToDeleteId.value = employeeId;
  isConfirmDeleteOpen.value = true;
};

const deleteEmployeeConfirmed = async () => {
  if (!employeeToDeleteId.value) return;

  loadingAddEmployee.value = true;
  addEmployeeMessage.value = "";
  addEmployeeError.value = false;

  try {
    const { error } = await supabase
      .from("profiles")
      .delete()
      .eq("id", employeeToDeleteId.value);

    if (error) throw error;
    addEmployeeMessage.value = "Employee deleted successfully!";
    employees.value = employees.value.filter(
      (emp) => emp.id !== employeeToDeleteId.value
    );
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    employeeToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    console.error("Error deleting employee:", error.message);
    addEmployeeMessage.value = "Failed to delete employee: " + error.message;
    addEmployeeError.value = true;
  } finally {
    loadingAddEmployee.value = false;
  }
};

const resetForm = () => {
  isEditingEmployee.value = false;
  employeeForm.value = {
    id: "",
    email: "",
    full_name: "",
    password: "",
    role: "cashier",
    phone: "",
    address: "",
    is_active: true,
  };
  addEmployeeMessage.value = "";
  addEmployeeError.value = false;
};

const pageLoading = ref(true); // Controls the loading state for the entire page
const hasAdminRole = ref(false);

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    console.error("Error fetching user role:", error.message);
    hasAdminRole.value = false;
    return;
  }
  if (!data) {
    console.error("No profile data found for user.");
    hasAdminRole.value = false;
    return;
  }
  hasAdminRole.value = data?.role === "admin";
  if (!hasAdminRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminRole.value === true) {
      await fetchEmployees();
    }
  } catch (error: any) {
    console.error("Error during initialization:", error.message);
    addEmployeeMessage.value = "Terjadi kesalahan saat memuat data.";
    addEmployeeError.value = true;
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminRole.value) {
      await fetchEmployees();
    }
  } else {
    hasAdminRole.value = false;
    employees.value = [];
    router.push("/login");
  }
});
</script>

<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border-left-color: #09f;
  animation: spin 1s ease infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
